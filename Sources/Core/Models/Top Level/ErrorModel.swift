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

/// Error model returned by the BLOCKv server.
struct ErrorModel: Equatable {
    let requestId: String
    let code: Int
    let message: String

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case code = "error"
        case message
    }

}

extension ErrorModel: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requestId = try container.decodeIfPresent(String.self, forKey: .requestId) ?? ""
        code = try container.decodeIfPresent(Int.self, forKey: .code) ?? -1
        message = try container.decode(String.self, forKey: .message)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(requestId, forKey: .requestId)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
    }

}
