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

/// This class handles OAuth2 and implementes a credential refresh system.
class OAuth2Handler: RequestAdapter, RequestRetrier {

    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?, _ refreshToken: String?) -> Void
    
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
    
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []
    
    // MARK: - Initialization
    
    init(appID: String, baseURLString: String, accessToken: String = "", refreshToken: String = "") {
        self.appID = appID
        self.baseURLString = baseURLString
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    // MARK: - RequestAdapter
    
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
    
    // MARK: - RequestRetrier
    
    /// Called after a request being executed by the specified session manager
    /// encountering an error.
    ///
    /// Determines whether a request should be retried encountering an error.
    ///
    /// Thread safety is important here. There may be many requests executing for each session manager.
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        lock.lock() ; defer { lock.unlock() }
        
        // check for an unauthorised response
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            
            // A large number of request can be racing at the same time.
            // Here the requests are stored until the refresh completes.
            requestsToRetry.append(completion)
            
            //TODO: If refresh fails, refreshTokens will be called continiously. A backoff policy should be implemented.
            
            if !isRefreshing {
                refreshTokens { [weak self] (succeeded, accessToken, refreshToken) in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
                    
                    if !succeeded {
                        printBV(error: "Access token - Refresh failed")
                    }
                    
                    // store the new access token
                    if let accessToken = accessToken {
                        printBV(info: "Access token - Refresh successful")
                        strongSelf.accessToken = accessToken
                    }
                    
                    strongSelf.requestsToRetry.forEach { $0(succeeded, 0.0) }
                    strongSelf.requestsToRetry.removeAll()
                }
                
            }
            
        } else {
            completion(false, 0.0)
        }
        
        // check for rate limiting
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 403 {
            print("◦◦◦ BV SDK ◦ Wanring: Server is rate limiting requests.")
        }
        
    }
    
    // MARK: - Private - Refresh Tokens
    
    /// Attemps to refresh the accessToken.
    private func refreshTokens(completion: @escaping RefreshCompletion) {
        
        printBV(error: "Access token - Attempting refresh")
        
        guard !isRefreshing else { return }
        isRefreshing = true
        
        // construct a request to refresh the token
        let urlString = "\(baseURLString)/v1/access_token"
        
        let headers: HTTPHeaders = [
            "App-Id": self.appID,
            "Authorization": "Bearer \(refreshToken)"
        ]
        
        // execute the request from the refresh session manager
        refreshSessionManager.request(urlString, method: .post, headers: headers)
            .responseJSONDecodable { [weak self] (dataResponse: DataResponse<BaseModel<RefreshModel>>) in
            
            guard let strongSelf = self else { return }
            
            switch dataResponse.result {
            case let .success(val):
                // fire completion handler passing in the access token
                completion(true, val.payload.accessToken.token, nil)
            case let .failure(err):
                //TODO: Better to propagate the error here rather than return false.
                // Maybe not, perhaps succeeded false is enough. Auto-logout is
                // triggered from there.
                completion(false, nil, nil)
            }

            strongSelf.isRefreshing = false
               
        }
        
    }
    
    /// Call this function when a network request returns auth credentials.
    /// E.g. login, register.
    func setTokens(accessToken: String, refreshToken: String) {
        //FIXME: Threading considerations?

        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
}
