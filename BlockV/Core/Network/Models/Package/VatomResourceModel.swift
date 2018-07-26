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

public struct VatomResourceModel: Equatable {

    //TODO: Split type into type and format: "3D" and "Scene"

    public let name: String // e.g. Scene
    public let type: String // e.g. ResourceTypes::3D::Scene
    public let url: URL     // e.g. https://cdndev.blockv.net/.../harvelles_menu_icon.png

    enum CodingKeys: String, CodingKey {
        case name
        case type = "resourceType"
        case value
    }

    enum ValuesCodingKeys: String, CodingKey {
        case urlString = "value"
    }

}

// MARK: Codable

extension VatomResourceModel: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)

        // flatten the `value` container
        var valueContainer = container.nestedContainer(keyedBy: ValuesCodingKeys.self, forKey: .value)
        try valueContainer.encode(url, forKey: .urlString)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        type = try values.decode(String.self, forKey: .type)

        // un-nest `url` from the value container.
        let valueContainer = try values.nestedContainer(keyedBy: ValuesCodingKeys.self, forKey: .value)
        url = try valueContainer.decode(URL.self, forKey: .urlString)
    }

}

// MARK: Hashable

extension VatomResourceModel: Hashable {

    public var hashValue: Int {
        return name.hashValue ^ type.hashValue ^ url.hashValue
    }
}
