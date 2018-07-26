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

/// Represents the top-level JSON structure for success (200...299) BLOCKv platform responses.
public struct BaseModel<T: Decodable>: Decodable {
    let payload: T
}

/// Represents a meta data object.
///
/// This structure forms part of a subset of responses.
public struct MetaModel: Codable, Equatable {
    let dataType: String
    public let whenCreated: Date
    public let whenModified: Date

    enum CodingKeys: String, CodingKey {
        case dataType = "data_type"
        case whenCreated = "when_created"
        case whenModified = "when_modified"
    }

}
