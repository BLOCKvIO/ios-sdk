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

/// User model
public struct UserModel: Equatable {

    // Public

    public let id: String
    public let firstName: String
    public let lastName: String
    public let isNamePublic: Bool
    public let isAvatarPublic: Bool
    public let birthday: String
    public let guestID: String
    public let nonPushNotification: Bool
    public let language: String
    public let meta: MetaModel
    public let avatarURL: URL?
    public let isPasswordSet: Bool
    public let userConsents: [ConsentModel]

    // Internal

    public let systemProperties: SystemProperties

    enum CodingKeys: String, CodingKey {
        case id
        case meta
        case properties
        case systemProperties = "system_properties"
    }

    enum PropertiesCodingKeys: String, CodingKey {
        case firstName           = "first_name"
        case lastName            = "last_name"
        case isNamePublic        = "name_public"
        case isAvatarPublic      = "avatar_public"
        case avatarURL           = "avatar_uri"
        case birthday            = "birthday"
        case guestID             = "guest_id"
        case nonPushNotification = "nonpush_notification"
        case language            = "language"
        case isPasswordSet       = "is_password_set"
        case userConsents        = "user_consents"
    }

    public struct SystemProperties: Codable, Equatable {
        public let isAdmin: Bool
        public let isMerchant: Bool
        public let lastLogin: Date
        public let isActivated: Bool

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
        isNamePublic        = try propertiesContainer.decode(Bool.self, forKey: .isNamePublic)
        isAvatarPublic      = try propertiesContainer.decode(Bool.self, forKey: .isAvatarPublic)
        birthday            = try propertiesContainer.decode(String.self, forKey: .birthday)
        guestID             = try propertiesContainer.decode(String.self, forKey: .guestID)
        nonPushNotification = try propertiesContainer.decode(Bool.self, forKey: .nonPushNotification)
        language            = try propertiesContainer.decode(String.self, forKey: .language)

        userConsents        = try propertiesContainer.decodeSafelyIfPresentArray(of: ConsentModel.self, forKey: .userConsents) ?? []
        isPasswordSet       = try propertiesContainer.decodeIfPresent(Bool.self, forKey: .isPasswordSet) ?? false

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
        try propertiesContainer.encode(isNamePublic, forKey: .isNamePublic)
        try propertiesContainer.encode(isAvatarPublic, forKey: .isAvatarPublic)
        try propertiesContainer.encode(avatarURL, forKey: .avatarURL)
        try propertiesContainer.encode(birthday, forKey: .birthday)
        try propertiesContainer.encode(guestID, forKey: .guestID)
        try propertiesContainer.encode(nonPushNotification, forKey: .nonPushNotification)
        try propertiesContainer.encode(language, forKey: .language)
        try propertiesContainer.encode(isPasswordSet, forKey: .isPasswordSet)
        try propertiesContainer.encode(userConsents, forKey: .userConsents)

    }

}

/// Consent Model
public struct ConsentModel: Equatable {
    
    // Public

    public let meta: MetaModel
    public let appId: String
    public let version: Int
    public let address: String
    
    enum CodingKeys: String, CodingKey {
        case meta
        case appId = "app_id"
        case version
        case address
    }
    
}

// MARK: - Codable

extension ConsentModel: Codable {
    
    public init(from decoder: Decoder) throws {
        // top-level
        let items        = try decoder.container(keyedBy: CodingKeys.self)
        meta             = try items.decode(MetaModel.self, forKey: .meta)
        appId            = try items.decode(String.self, forKey: .appId)
        version          = try items.decode(Int.self, forKey: .version)
        address          = try items.decode(String.self, forKey: .address)
    }

    public func encode(to encoder: Encoder) throws {
        // top-level
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(meta, forKey: .meta)
        try container.encode(appId, forKey: .appId)
        try container.encode(version, forKey: .version)
        try container.encode(address, forKey: .address)
    }
}
