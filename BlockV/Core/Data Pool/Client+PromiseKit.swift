//
//  BLOCKv AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BLOCKv SDK License (the "License"); you may not use this file or
//  the BLOCKv SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BLOCKv SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import Foundation
import PromiseKit

// PromiseKit Overlays on Client
internal extension Client {

    /// Performs a request on a given endpoint.
    ///
    /// - Parameter endpoint: Endpoint on which to perform the request.
    /// - Returns: A promise that resolves with the response as `Data`.
    func request(_ endpoint: Endpoint<Void>) -> Promise<Data> {

        return Promise { seal in
            // convert result type into promise
            self.request(endpoint) { result in
                switch result {
                case .success(let model):
                    seal.fulfill(model)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }

    }

    /// Performs a request on a given endpoint.
    ///
    /// - Parameter endpoint: Endpoint on which to perform the request.
    /// - Returns: A promise that resolves with the reponse as JSON.
    func requestJSON(_ endpoint: Endpoint<Void>) -> Promise<Any> {

        return Promise { seal in
            self.requestJSON(endpoint) { result in
                switch result {
                case .success(let model):
                    seal.fulfill(model)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }

    }
    
    /// Performs a request on a given endpoint.
    ///
    /// - Parameter endpoint: Endpoint on which to perform the request.
    /// - Returns: A promise that resolves with the top-level structure parsed out.
    func requestJSONParsed(_ endpoint: Endpoint<Void>) -> Promise<(requestID: String, payload: [String: Any])> {
        
        self.requestJSON(endpoint)
            .then(on: .global(qos: .userInitiated)) { json -> Promise<(requestID: String, payload: [String: Any])> in
                // parse out the standard top-level BLOCKv platform response
                guard
                    let json = json as? [String: Any],
                    let payload = json["payload"] as? [String: Any],
                    let requestId = json["request_id"] as? String
                    else { throw BVError.modelDecoding(reason: "Unable to parse top level payload.") }
                
                return Promise.value((requestId, payload))
                
        }
        
    }

    func request<T: Decodable>(_ endpoint: Endpoint<T>) -> Promise<T> {

        return Promise { seal in
            // convert result type into promise
            self.request(endpoint) { result in
                switch result {
                case .success(let model):
                    seal.fulfill(model)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }

    }

}
