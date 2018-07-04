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

// MARK: Defines

typealias Parameters = [String: Any]
typealias Path = String

// MARK: Endpoint

/// This class represents a server endpoint.
///
/// The generic `response` parameter specifies the type of the response
/// from the endpoint.
public final class Endpoint<Response> {

    let method: HTTPMethod
    let path: Path
    let parameters: Parameters?
    let encoding: ParameterEncoding

    //TODO: Does it make sense for json to be the default encoding?
    init(method: HTTPMethod = .get,
         path: Path,
         parameters: Parameters? = nil,
         encoding: ParameterEncoding = JSONEncoding.default) {

        self.method = method
        self.path = path
        self.parameters = parameters
        self.encoding = encoding

    }

}

/// Container for multiform data body part.
struct MultiformBodyPart {
    let data: Data
    let name: String
    let fileName: String
    let mimeType: String
}

/// This class represent a server endpoint to upload multipart form data.
///
/// The generic `response` parameter specifies the type of the response
/// from the endpoint.
public final class UploadEndpoint<Response> {

    let path: Path
    let bodyPart: MultiformBodyPart

    init(path: Path, bodyPart: MultiformBodyPart) {
        self.path = path
        self.bodyPart = bodyPart
    }

}
