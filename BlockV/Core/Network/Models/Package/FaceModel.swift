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

/// A simple struct that models a template face.
///
/// FaceModel has value semantics and is immutable.
public struct FaceModel: Equatable {

    // MARK: - Properties

    public let id: String
    public let templateID: String
    public let meta: MetaModel
    public let properties: Properties

    // MARK: - Convenience

    /// Boolean indicating whether this face is a native face.
    public let isNative: Bool

    /// Boolean indicating whether this face is a Web face.
    ///
    /// - important: Only secure connections are regarded as Web faces (i.e https).
    public let isWeb: Bool

}

// MARK: - Codable

extension FaceModel: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case templateID = "template"
        case meta
        case properties
    }

    public struct Properties: Codable, Equatable {

        public let displayURL: String
        public let constraints: Constraints
        public let resources: [String]
        public let config: JSON?

        enum CodingKeys: String, CodingKey {
            case displayURL = "display_url"
            case constraints
            case resources
            case config
        }

        public struct Constraints: Codable, Equatable {

            public let viewMode: String
            public let platform: String

            enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
                case viewMode = "view_mode"
                case platform
            }

        }
    }

    public init(from decoder: Decoder) throws {
        let items = try decoder.container(keyedBy: CodingKeys.self)
        id         = try items.decode(String.self, forKey: .id)
        templateID = try items.decode(String.self, forKey: .templateID)
        properties = try items.decode(Properties.self, forKey: .properties)
        meta       = try items.decode(MetaModel.self, forKey: .meta)
        // convenience
        isNative   = properties.displayURL.hasPrefix("native://")
        isWeb      = properties.displayURL.hasPrefix("https://")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(templateID, forKey: .templateID)
        try container.encode(properties, forKey: .properties)
        try container.encode(meta, forKey: .meta)
    }

}

// MARK: - Hashable

extension FaceModel: Hashable {

    /// Faces are uniquely identified by their platform identifier.
    public var hashValue: Int {
        return id.hashValue
    }

}
