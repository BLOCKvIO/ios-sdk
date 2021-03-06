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

public struct VatomUpdateModel: Decodable, Equatable {

    public let numberUpdated: Int
    public let numberErrors: Int
    public let errorMessage: [String: String]
    /// List of ids that were successfuly updated.
    public let ids: [String]

    enum CodingKeys: String, CodingKey {
        case numberUpdated = "num_updated"
        case numberErrors = "num_errors"
        case errorMessage = "error_messages"
        case ids
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        numberUpdated = try values.decode(Int.self, forKey: .numberUpdated)
        numberErrors = try values.decode(Int.self, forKey: .numberErrors)
        errorMessage = try values.decodeIfPresent([String: String].self, forKey: .errorMessage) ?? [:]
        ids = try values.decode([String].self, forKey: .ids)
    }

}
