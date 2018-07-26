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

/// Possible view modes a face may define for presentation.
public enum ViewMode: String {

    case icon
    case activated
    case fullscreen
    case card
    case background

}

/// A simple struct that models a template face.
public struct FaceModel: Codable, Equatable {

    public let id: String
    public let templateName: String
    public let meta: MetaModel
    public let properties: Properties

    enum CodingKeys: String, CodingKey {
        case id
        case templateName = "template"
        case meta
        case properties
    }

    public struct Properties: Codable, Equatable {

        public let displayURL: URL
        public let constraints: Constraints
        public let resources: [String]

        enum CodingKeys: String, CodingKey {
            case displayURL = "display_url"
            case constraints
            case resources
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

}

// MARK: - Hashable

extension FaceModel: Hashable {

    /// Faces are uniquely identified by their platform identifier.
    public var hashValue: Int {
        return id.hashValue
    }

}
