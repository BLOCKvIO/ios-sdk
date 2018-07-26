//
//  BlockV AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BlockV SDK License (the "License"); you may not use this file or
//  the BlockV SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BlockV SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import Foundation
import Alamofire

/// This class handles BLOCKv OAuth2 and implements a credential refresh system.
///
/// This class will handle an invalid access token error by automatically refreshing
/// the access token and retrying all failed requests in the same order they failed.
final class OAuth2Handler: RequestAdapter, RequestRetrier {

    typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?, _ refreshToken: String?) -> Void

    /// Session manager used soley for refreshing the access token.
    fileprivate let refreshSessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        return SessionManager(configuration: configuration)
    }()

    // MARK: - Properties

    fileprivate let lock = NSLock()
    fileprivate let appID: String
    fileprivate let baseURLString: String

    fileprivate var accessToken: String
    fileprivate var refreshToken: String

    fileprivate let internalQueue = DispatchQueue(label: "com.blockv.io.internal.sync")

    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []

    // MARK: - Initialization

    init(appID: String, baseURLString: String, accessToken: String = "", refreshToken: String = "") {
        self.appID = appID
        self.baseURLString = baseURLString
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    // MARK: - Request Adapter

    /// Inspects and adapts the specified `URLRequest` in some manner if necessary and returns the result.
    ///
    /// Adapts a `URLRequest` to include the Authorization header.
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {

        if let urlString = urlRequest.url?.absoluteString, urlString.hasPrefix(baseURLString) {
            var urlRequest = urlRequest
            // inject the bearer on every request
            // TODO: Don't send on auth calls (register / login)
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            return urlRequest
        }
        return urlRequest
    }

    // MARK: - Request Retrier

    /// Determines whether the `Request` should be retried by calling the `completion` closure.
    ///
    /// This operation is fully asynchronous. Any amount of time can be taken to determine whether
    /// the request needs to be retried. The one requirement is that the completion closure is
    /// called to ensure the request is properly cleaned up after.
    ///
    /// Another important note is that this authentication system could be shared between multiple
    /// session managers. For example, you may need to use both a default and ephemeral session
    /// configuration for the same set of web services. The implementation below allows an instance
    /// OAuth2Handler to be shared across multiple session managers to manage the single
    /// refresh flow. In other words, thread safetly is important.
    func should(_ manager: SessionManager, retry request: Request, with error: Error,
                completion: @escaping RequestRetryCompletion) {

        /*
         This lock ensures exclusive access to `requestsToRetry` and `isRefreshing` variables.
         */
        lock.lock() ; defer { lock.unlock() }

        // check for an unauthorised response
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {

            // ensure request are retried only once
            guard request.retryCount == 0 else {
                // don't retry the request
                completion(false, 0.0)
                return
            }

            // ensure the error payload indicates a token refresh is required
            guard
                let data = request.delegate.data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let errorDictionary = json as? [String: String],
                // Important to check for both "token expired" and "Unauthorized" messages.
                (errorDictionary["exp"] == "token expired" || errorDictionary["message"] == "Unauthorized") else {
                    //printBV(info: "401 received. Unrelated to access token. Access token refresh declined.")
                    // don't retry the request
                    completion(false, 0.0)
                    return
            }

            // store the completion hanlder
            requestsToRetry.append(completion)
            // attemp to fetch a new access token
            refreshAndUpdate()

        } else {
            // don't retry the request
            completion(false, 0.0)
        }

        //TODO: Inform viewer they may be rate limited 403

    }

    // MARK: - Private - Refresh Tokens

    /// Responsible for ensuring only a sinlge refresh is in progress.
    ///
    /// The thread safety of the `isRefreshing`, `requestsToRetry`, and `completionsToFire` is important.
    private func refreshAndUpdate() {

        // do nothing if currently refreshing
        guard !isRefreshing else { return }

        refreshTokens { [weak self] (succeeded, accessToken, _) in
            guard let strongSelf = self else { return }

            /*
             This lock (within the context of the outer locks) ensures exclusive access to `requestsToRetry`.
             When this closure is called, it operates on `requestToRetry` and `manualTokenCallbacks`
             which must be exclusive.
             */
            strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }

            if !succeeded {
                printBV(error: "Access token - Not Updated")
            }

            // store the new access token
            if let accessToken = accessToken {
                strongSelf.accessToken = accessToken
                printBV(info: "Access token - Updated")
            }

            // call completions to retry request
            strongSelf.requestsToRetry.forEach { $0(succeeded, 0.0) }
            strongSelf.requestsToRetry.removeAll()

            // call completions to doll out the access token
            strongSelf.manualTokenCallbacks.forEach { $0(succeeded, accessToken) }
            strongSelf.manualTokenCallbacks.removeAll()

        }

    }

    /// Solely responsible for obtaining a new access token from the network.
    ///
    /// - Parameter completion: The completion closure to call once the token refresh completes.
    private func refreshTokens(completion: @escaping RefreshCompletion) {

        printBV(info: "Access token - Attempting refresh")

        guard !isRefreshing else {
            assertionFailure("Calling functions should ensure a refresh isn't triggered while one is in flight.")
            return
        }
        isRefreshing = true

        // construct a request to refresh the access token
        let urlString = "\(baseURLString)/v1/access_token"

        let headers: HTTPHeaders = [
            "App-Id": self.appID,
            "Authorization": "Bearer \(refreshToken)"
        ]

        // execute the request on the refresh session manager
        refreshSessionManager.request(urlString, method: .post, headers: headers)
            .responseJSONDecodable { [weak self] (dataResponse: DataResponse<BaseModel<RefreshModel>>) in

            guard let strongSelf = self else { return }

            switch dataResponse.result {
            case let .success(val):
                printBV(info: "Access token - Refresh successful")
                // invoke with success
                completion(true, val.payload.accessToken.token, nil)

            case let .failure(err):
                printBV(error: "Access token - Refresh failed")
                printBV(error: err.localizedDescription)

                // check if the error payload indicates the refresh token is invlaid
                if let statusCode = dataResponse.response?.statusCode, (400...499) ~= statusCode {
                    // broadcast to inform user authorization is required
                    NotificationCenter.default.post(name: Notification.Name.BVInternal.UserAuthorizationRequried,
                                                    object: nil)
                }

                // invoke with failure
                completion(false, nil, nil)

            }

            strongSelf.isRefreshing = false

        }

    }

    /// Call this method to explicilty set the OAuth2Handler's access and refresh tokens.
    ///
    /// This is useful for requests (e.g. login, register) that return token credentials
    /// (other than the token refresh mechanism encapsulated in this class).
    func set(accessToken: String, refreshToken: String) {
        //TODO: Look at threading considerations.
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    // MARK: - Manual Access Token Refresh

    typealias TokenCompletion = (_ success: Bool, _ accessToken: String?) -> Void

    private var manualTokenCallbacks: [TokenCompletion] = []

    /// Retrieves and refreshes the SDKs access token.
    ///
    /// - Parameter completion: The closure to call once an access token has been obtained
    /// form the BLOCKv platform.
    func forceAccessTokenRefresh(completion: @escaping TokenCompletion) {

        //FIXME: If the refresh fails - should a typed error be passed to the closure (in stead of bool = false)?

        // move to a background queue (this method may be called on the main thread - which we don't want to block)
        internalQueue.async {

            /*
             This lock ensures exclusive access to `manualTokenCallbacks` and `isRefreshing` variables.
             */
            self.lock.lock() ; defer { self.lock.unlock() }
            self.manualTokenCallbacks.append(completion)
            self.refreshAndUpdate()
        }

    }

}
