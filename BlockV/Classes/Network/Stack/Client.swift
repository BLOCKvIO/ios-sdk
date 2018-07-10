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

    /// Request that returns raw data.
    func request(_ endpoint: Endpoint<Void>, completion: @escaping (Data?, BVError?) -> Void )

    /// Request that returns native object (must conform to decodable).
    func request<Response>(_ endpoint: Endpoint<Response>,
                           completion: @escaping (Response?, BVError?) -> Void ) where Response: Decodable

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
    /// This is usefull for actions whose reponse payloads are not know since reactors may change at
    /// any time.
    ///
    /// NOTE: Raw requests do not partake in OAuth and general lifecycle handling.
    ///
    /// - Parameters:
    ///   - endpoint: Endpoint for the request
    ///   - completion: The completion handler to call when the request is completed.
    func request(_ endpoint: Endpoint<Void>, completion: @escaping (Data?, BVError?) -> Void) {

        // create request
        let request = self.sessionManager.request(
            url(path: endpoint.path),
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding
        )

        // configure validation
        request.validate() //TODO: May need manual validation

        request.responseData { (dataResponse) in
            switch dataResponse.result {
            case let .success(data): completion(data, nil)
            case let .failure(err):

                //TODO: The error should be parsed and a BVError created and passed in.

                // check for a BVError
                if let err = err as? BVError {
                    completion(nil, err)
                } else {
                    // create a wrapped networking errir
                    let error = BVError.networkingError(error: err)
                    completion(nil, error)
                }
            }
        }

    }

    /// Performs a request on a given endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: Endpoint for the request
    ///   - completion: The completion handler to call when the request is completed.
    func request<Response>(_ endpoint: Endpoint<Response>,
                                  completion: @escaping (Response?, BVError?) -> Void ) where Response: Decodable {

        // create request (starts immediately)
        let request = self.sessionManager.request(
            url(path: endpoint.path),
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding
        )

        // configure validation - will cause an error to be generated for unacceptable status code or MIME type.
        //request.validate()

        // parse out a native model (within the base model)
        request.validate().responseJSONDecodable(queue: self.queue,
                                                 decoder: blockvJSONDecoder) { (dataResponse: DataResponse<Response>) in

            // DEBUG
            //            let json = try? JSONSerialization.jsonObject(with: dataResponse.data!, options: [])
            //            dump(json)

            switch dataResponse.result {
            case let .success(val):

                /*
                 Not all responses (even in the 200 range) are wrapped in the `BaseModel`. Endpoints must be treated
                 on a per-endpoint basis.
                 */

                // extract auth tokens if available
                if let model = val as? BaseModel<AuthModel> {
                    self.oauthHandler.set(accessToken: model.payload.accessToken.token,
                                          refreshToken: model.payload.refreshToken.token)
                }

                // ensure the payload was parsed correctly
                // on success, the payload should alway have a value
                //                guard let payload = val.payload else {
                //                    let error = BVError.modelDecoding(reason: "Payload model not parsed correctly.")
                //                    completion(nil, error)
                //                    return
                //                }

                completion(val, nil)

                //TODO: Add some thing like this to pull back to a completion thread?
                /*
                 This tread should be different to the response handler thread...
                 (queue ?? DispatchQueue.main).async { completionHandler(dataResponse) }
                 */

            case let .failure(err):

                // DEBUG
                //                if let data = dataResponse.data {
                //                    let json = String(data: data, encoding: String.Encoding.utf8)
                //                    print("Failure Response: \(json)")
                //                }

                //FIXME: Can this error casting be done away with?
                if let err = err as? BVError {
                    completion(nil, err)
                } else {
                    let error = BVError.networkingError(error: err)
                    completion(nil, error)
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
                //print("Upload response: \(upload.response.debugDescription)")

                // upload progress
                upload.uploadProgress { progress in
                    progressCompletion(Float(progress.fractionCompleted))
                }
                upload.validate()

                // parse out a native model (within the base model)
                //TODO: If is fine to capture self here?
                upload.responseJSONDecodable(queue: self.queue,
                                             decoder: self.blockvJSONDecoder) { (dataResponse: DataResponse<Response>)
                                                in

                    ///
                    switch dataResponse.result {
                    case let .success(val):
                        completion(val, nil)

                    case let .failure(err):
                        // check for a BVError
                        if let err = err as? BVError {
                            completion(nil, err)
                        } else {
                            // create a wrapped networking errir
                            let error = BVError.networkingError(error: err)
                            completion(nil, error)
                        }
                    }

                }

            case .failure(let encodingError):
                //print(encodingError)

                let error = BVError.networkingError(error: encodingError)
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
