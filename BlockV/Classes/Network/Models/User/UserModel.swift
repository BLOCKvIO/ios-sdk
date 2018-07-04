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

/// User model
public struct UserModel: Equatable {

    // Public

    public let id: String
    public let firstName: String
    public let lastName: String
    public let namePublic: Bool
    public let avatarPublic: Bool
    public let birthday: String
    public let guestID: String
    public let nonPushNotification: Bool
    public let language: String
    public let meta: MetaModel
    public let avatarURL: URL?

    // Internal

    let systemProperties: SystemProperties

    enum CodingKeys: String, CodingKey {
        case id
        case meta
        case properties
        case systemProperties = "system_properties"
    }

    enum PropertiesCodingKeys: String, CodingKey {
        case firstName           = "first_name"
        case lastName            = "last_name"
        case namePublic          = "name_public"
        case avatarPublic        = "avatar_public"
        case avatarURL           = "avatar_uri"
        case birthday            = "birthday"
        case guestID             = "guest_id"
        case nonPushNotification = "nonpush_notification"
        case language            = "language"
    }

    struct SystemProperties: Codable, Equatable {
        let isAdmin: Bool
        let isMerchant: Bool
        let lastLogin: Date
        let isActivated: Bool

        enum CodingKeys: String, CodingKey {
            case isAdmin     = "is_admin"
            case isMerchant  = "is_merchant"
            case lastLogin   = "last_login"
            case isActivated = "activated"
        }
    }

}

// MARK: - Codable

extension UserModel: Codable {

    public init(from decoder: Decoder) throws {
        // top-level
        let items        = try decoder.container(keyedBy: CodingKeys.self)
        id               = try items.decode(String.self, forKey: .id)
        meta             = try items.decode(MetaModel.self, forKey: .meta)
        systemProperties = try items.decode(SystemProperties.self, forKey: .systemProperties)

        // de-nest properties to top level
        let propertiesContainer = try items.nestedContainer(keyedBy: PropertiesCodingKeys.self, forKey: .properties)
        firstName           = try propertiesContainer.decode(String.self, forKey: .firstName)
        lastName            = try propertiesContainer.decode(String.self, forKey: .lastName)
        namePublic          = try propertiesContainer.decode(Bool.self, forKey: .namePublic)
        avatarPublic        = try propertiesContainer.decode(Bool.self, forKey: .avatarPublic)
        birthday            = try propertiesContainer.decode(String.self, forKey: .birthday)
        guestID             = try propertiesContainer.decode(String.self, forKey: .guestID)
        nonPushNotification = try propertiesContainer.decode(Bool.self, forKey: .nonPushNotification)
        language            = try propertiesContainer.decode(String.self, forKey: .language)

        // Avatar URLs generally have a default value - but this is not guaranteed.
        avatarURL           = propertiesContainer.decodeSafely(Safe<URL>.self, forKey: .avatarURL)?.value

    }

    public func encode(to encoder: Encoder) throws {
        // top-level
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(meta, forKey: .meta)
        try container.encode(systemProperties, forKey: .systemProperties)

        // nest properties one level
        var propertiesContainer = container.nestedContainer(keyedBy: PropertiesCodingKeys.self, forKey: .properties)
        try propertiesContainer.encode(firstName, forKey: .firstName)
        try propertiesContainer.encode(lastName, forKey: .lastName)
        try propertiesContainer.encode(namePublic, forKey: .namePublic)
        try propertiesContainer.encode(avatarPublic, forKey: .avatarPublic)
        try propertiesContainer.encode(avatarURL, forKey: .avatarURL)
        try propertiesContainer.encode(birthday, forKey: .birthday)
        try propertiesContainer.encode(guestID, forKey: .guestID)
        try propertiesContainer.encode(nonPushNotification, forKey: .nonPushNotification)
        try propertiesContainer.encode(language, forKey: .language)

    }

}
