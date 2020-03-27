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
import Alamofire

extension DataRequest {

    /// Adds a handler to be called once the request has finnished.
    ///
    /// - Parameters:
    ///   - queue: The queue on which the completion handler is dispatched.
    ///   - decoder: The JSON decoder used to decode the response.
    ///   - completionHandler: A closure to be executed once the request has finished.
    /// - Returns: The request.
    @discardableResult
    public func responseJSONDecodable<T: Decodable>(
        queue: DispatchQueue? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        completionHandler: @escaping (DataResponse<T>) -> Void)
        -> Self {

            // construct the response serializer
            let responseSerializser = DataResponseSerializer<T> { _, _, data, error in

                // handle error
                if let topLevelError = error {

                    printBV(error: topLevelError.localizedDescription)

                    // 1. This error is an HTTP from Alamofire.
                    // 2. The error from our server needs to be unwrapped and passed back.

                    guard let validData = data, validData.count > 0 else {
                        return .failure(BVError.networking(error:
                            AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)))
                    }

                    do {
                        // decode the payload into an blockv error object
                        let errorModel = try decoder.decode(ErrorModel.self, from: validData)
                        let error = BVError.platform(reason:
                            BVError.PlatformErrorReason(code: errorModel.code, message: errorModel.message, requestId: errorModel.requestId))
                        return .failure(error) //TODO: Alamofire error is lost in this case.

                    } catch let DecodingError.keyNotFound(key, context) {
                        return .failure(BVError.modelDecoding(reason:
                            "Key not found: \(key) in context: \(context.debugDescription)"))
                    } catch let DecodingError.valueNotFound(value, context) {
                        return .failure(BVError.modelDecoding(reason:
                            "Value not found: \(value) in context: \(context.debugDescription)"))
                    } catch {
                        return .failure(BVError.modelDecoding(reason: error.localizedDescription))
                    }

                }

                // handle success
                guard let validData = data, validData.count > 0 else {
                    //FIXME: Handle this case
                    //                    if let response = response,
                    //                        emptyDataStatusCodes.contains(response.statusCode) {
                    //                        return NSNull()
                    //                    }
                    return .failure(BVError.networking(error:
                        AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)))
                }

                // decode the payload into a blockv model object
                do {
                    let object = try decoder.decode(T.self, from: validData)
                    return .success(object)
                } catch let DecodingError.keyNotFound(key, context) {
                    return .failure(BVError.modelDecoding(reason: "Key not found: \(key) in context: \(context)"))
                } catch let DecodingError.valueNotFound(value, context) {
                    return .failure(BVError.modelDecoding(reason:
                        "Value not found: \(value) in context: \(context.debugDescription)"))
                } catch {
                    return .failure(BVError.modelDecoding(reason: error.localizedDescription))
                }

            }

            return response(queue: queue, responseSerializer: responseSerializser, completionHandler: completionHandler)
    }

}
