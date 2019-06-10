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

protocol ClientProtocol {

    typealias RawCompletion = (Swift.Result<Data, BVError>) -> Void

    /// Request that returns raw data.
    func request(_ endpoint: Endpoint<Void>, completion: @escaping RawCompletion)

    /// Request that returns native object (must conform to decodable).
    func request<T>(_ endpoint: Endpoint<T>, completion: @escaping (Swift.Result<T, BVError>) -> Void ) where T: Decodable

}

/// This class manages a networking client.
///
/// Client is invariant over:
/// - base url
/// - app id
///
/// To change these values a new client instance must be created.
/// ---------------------
///
/// Client is variant over:
/// - refresh token
/// - access token
///
/// The client may change their values over it's lifetime. The client's owner
/// may not change these values after initialization.
///
/// A client may be initialised with a refresh token. This allows the client
/// to attempt to obtain a new access token with requiring a auth call (i.e.
/// a call that returns a model conforming to `OAuthTokenModel`).
///
/// Models conforming to `OAuthTokenModel` allow for OAuth credentials to be
/// processes by the client.
final class Client: ClientProtocol {

    // MARK: - Properties

    private let sessionManager: Alamofire.SessionManager
    private let oauthHandler: OAuth2Handler
    private let baseURL: URL
    /// Response handlers are executed on this queue.
    private let queue = DispatchQueue(label: "com.blockv.api_request_queue", attributes: .concurrent)
    //TODO: Possibly add a completion queue, if speicifed, completion handlers would dispatched to it before being
    // called, or remain on the response queue if set to `nil`. This will remove the burden on the caller to change
    // queue (typically back to the main queue).

    class Configuration {
        let baseURLString: String
        let appID: String

        init(baseURLString: String, appID: String) {
            self.baseURLString = baseURLString
            self.appID = appID
        }

    }

    //TODO: The decoder should be passed into the client by it's owner - this would make it more flexible.
    /// JSON decoder configured for the blockv server.
    private lazy var blockvJSONDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    init(config: Configuration, oauthHandler: OAuth2Handler) {

        self.baseURL = URL(string: config.baseURLString)!

        var defaultHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        defaultHeaders["App-Id"] = config.appID

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHeaders

        // Uncomment to disable cache
        // configuration.urlCache = nil

        self.sessionManager = Alamofire.SessionManager(configuration: configuration)
        self.oauthHandler = oauthHandler
        self.sessionManager.adapter = oauthHandler
        self.sessionManager.retrier = oauthHandler

    }

    func getAccessToken(completion: @escaping (_ success: Bool, _ accessToken: String?) -> Void) {
        self.oauthHandler.forceAccessTokenRefresh(completion: completion)
    }

    // MARK: - Requests

    /// Endpoints generic over `void` complete by passing in the raw data response.
    ///
    /// This is useful for actions whose reponse payloads are not defined. For example, reactors may define their own
    /// inner payload structure.
    ///
    /// - important:
    /// Do not call this endpoint for auth related calls, e.g login. Raw requests do *not* support through the
    /// credential refresh mechanism. The access and refresh token will not be extracted and passed to the oauthhandler.
    ///
    /// - Parameters:
    ///   - endpoint: Endpoint for the request
    ///   - completion: The completion handler to call when the request is completed.
    func request(_ endpoint: Endpoint<Void>, completion: @escaping RawCompletion) {
        
        let endpoint = self.upgradeEndpoint(endpoint)

        // create request
        let request = self.sessionManager.request(
            url(path: endpoint.path),
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )

        // configure validation
        request.validate() //TODO: May need manual validation

        request.responseData(queue: queue) { (dataResponse) in
            switch dataResponse.result {
            case let .success(data):
                completion(.success(data))
            case let .failure(err):

                //TODO: The error should be parsed and a BVError created and passed in.

                // check for a BVError
                if let err = err as? BVError {
                    completion(.failure(err))
                } else {
                    // create a wrapped networking error
                    let error = BVError.networking(error: err)
                    completion(.failure(error))
                }
            }
        }

    }

    /// JSON Completion handler.
    typealias JSONCompletion = (Swift.Result<Any, BVError>) -> Void

    func requestJSON(_ endpoint: Endpoint<Void>, completion: @escaping JSONCompletion) {

        let endpoint = self.upgradeEndpoint(endpoint)

        // create request
        let request = self.sessionManager.request(
            url(path: endpoint.path),
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )

        // configure validation
        request.validate()
        request.responseJSON(queue: queue) { dataResponse in
            switch dataResponse.result {
            case let .success(json):
                completion(.success(json))
            case let .failure(err):
                // create a wrapped networking error
                let error = BVError.networking(error: err)
                completion(.failure(error))
            }
        }

    }

    /// Performs a request on a given endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: Endpoint for the request
    ///   - completion: The completion handler to call when the request is completed.
    func request<Response>(_ endpoint: Endpoint<Response>,
                           completion: @escaping (Swift.Result<Response, BVError>) -> Void ) where Response: Decodable {

        let endpoint = self.upgradeEndpoint(endpoint)

        // create request (starts immediately)
        let request = self.sessionManager.request(
            url(path: endpoint.path),
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )

        // configure validation - will cause an error to be generated for unacceptable status code or MIME type.
        //request.validate()

        // parse out a native model (within the base model)
        request.validate().responseJSONDecodable(queue: self.queue,
                                                 decoder: blockvJSONDecoder) { (dataResponse: DataResponse<Response>) in

            switch dataResponse.result {
            case let .success(val):

                /*
                 Certain endpoints return session tokens which need to be persisted (currently further up the chain)
                 and injected into the oauth session handler.
                 */

                // extract auth tokens if available
                if let model = val as? BaseModel<AuthModel> {
                    // inject token into session's oauth handler
                    self.oauthHandler.set(accessToken: model.payload.accessToken.token,
                                          refreshToken: model.payload.refreshToken.token)
                } else if let model = val as? OAuthTokenExchangeModel {
                    // inject token into session's oauth handler
                    self.oauthHandler.set(accessToken: model.accessToken,
                                          refreshToken: model.refreshToken)
                }

                completion(.success(val))

                //TODO: Add some thing like this to pull back to a completion thread?
                /*
                 This tread should be different to the response handler thread...
                 (queue ?? DispatchQueue.main).async { completionHandler(dataResponse) }
                 */

            case let .failure(err):

                //TODO: Can this error casting be done away with?
                if let err = err as? BVError {
                    completion(.failure(err))
                } else {
                    let error = BVError.networking(error: err)
                    completion(.failure(error))
                }

            }

        }

    }

    /// Performs an uplaod for a given endpoint.
    ///
    /// Reponse parsing works differently for upload. The `responseJSONDecodable` method transfroms the reponse with
    /// the completion closure.
    ///
    /// - Parameters:
    ///   - endpoint: Upload endpoint
    ///   - progressCompletion: Percent completed
    ///   - completion: The completion handler to call when the request is completed.
    func upload<Response>(_ endpoint: UploadEndpoint<Response>,
                          progressCompletion: @escaping (_ percent: Float) -> Void,
                          completion: @escaping (Response?, BVError?) -> Void ) where Response: Decodable {

        let serverURL = self.baseURL.appendingPathComponent(endpoint.path)

        self.sessionManager.upload(multipartFormData: { formData in

            // build multipart form
            formData.append(endpoint.bodyPart.data,
                            withName: endpoint.bodyPart.name,
                            fileName: endpoint.bodyPart.fileName,
                            mimeType: endpoint.bodyPart.mimeType)
        }, to: serverURL) { encodingResult in

            switch encodingResult {
            case .success(let upload, _, _):

                // upload progress
                upload.uploadProgress { progress in
                    progressCompletion(Float(progress.fractionCompleted))
                }
                upload.validate()

                // parse out a native model (within the base model)
                upload.responseJSONDecodable(queue: self.queue,
                                             decoder: self.blockvJSONDecoder) { (dataResponse: DataResponse<Response>)
                                                in

                    switch dataResponse.result {
                    case let .success(val):
                        completion(val, nil)

                    case let .failure(err):
                        // check for a BVError
                        if let err = err as? BVError {
                            completion(nil, err)
                        } else {
                            // create a wrapped networking errir
                            let error = BVError.networking(error: err)
                            completion(nil, error)
                        }
                    }

                }

            case .failure(let encodingError):
                let error = BVError.networking(error: encodingError)
                completion(nil, error)
            }
        }

    }

    // MARK: - Convenience

    /// Returns the full url including the base path.
    private func url(path: Path) -> URL {
        return baseURL.appendingPathComponent(path)
    }

}

extension Client {
    
    /// Upgrades the endpoint to V2.
    fileprivate func upgradeEndpoint<T>(_ endpoint: Endpoint<T>) -> Endpoint<T> {
        
        // check if cyclers are enabled, else return original
        guard Debug.isCyclersEnabled else { return endpoint }
        
        // check if the endpoint is eligible
        if (endpoint.method == .post && endpoint.path.contains("/user/vatom/action/")) ||
            (endpoint.method == .post && endpoint.path.contains("/vatoms")) ||
            (endpoint.method == .patch && endpoint.path.contains("/vatoms")) ||
            (endpoint.method == .post && endpoint.path.contains("/user/vatom/trash")) {
            
            // construct a new endpoint
            let path = endpoint.path.replacingOccurrences(of: "v1", with: "v2")
            var endpoint2 = Endpoint<T>(method: endpoint.method,
                                        path: path,
                                        parameters: endpoint.parameters,
                                        encoding: endpoint.encoding,
                                        headers: endpoint.headers)
            return endpoint2
        }
        
        // return original
        return endpoint
    }
    
}

public class Debug {
    
    static let cyclersKey = "com.blockv.io.cyclers.enabled"
    
    public static var isCyclersEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: cyclersKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: cyclersKey)
        }
    }
    
}
