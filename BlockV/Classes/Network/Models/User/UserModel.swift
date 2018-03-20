//
//  UserModel.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/02/21.
//

import Foundation

/// User model
public struct UserModel {
    
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
    
    public var avatarURL: URL
    
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
    
    struct SystemProperties: Codable {
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
    
    mutating func setURL(_ url: URL) {
        self.avatarURL = url
    }
    
}

// MARK: - AssetProviderEncodable

extension UserModel: AssetProviderEncodable {
    
    mutating func encodeEachURL(using encoder: URLEncoder, assetProviders: [AssetProvider]) {
        // encode url
        self.avatarURL = encoder(self.avatarURL, assetProviders)
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
        avatarURL           = try propertiesContainer.decode(URL.self, forKey: .avatarURL)
        birthday            = try propertiesContainer.decode(String.self, forKey: .birthday)
        guestID             = try propertiesContainer.decode(String.self, forKey: .guestID)
        nonPushNotification = try propertiesContainer.decode(Bool.self, forKey: .nonPushNotification)
        language            = try propertiesContainer.decode(String.self, forKey: .language)
        
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

// MARK: - Equatable

extension UserModel: Equatable {}

public func ==(lhs: UserModel, rhs: UserModel) -> Bool {
    return lhs.id == rhs.id &&
        lhs.firstName == rhs.firstName &&
        lhs.lastName == rhs.lastName &&
        lhs.namePublic == rhs.namePublic &&
        lhs.avatarPublic == rhs.avatarPublic &&
        lhs.avatarURL == rhs.avatarURL &&
        lhs.birthday == rhs.birthday &&
        lhs.guestID == rhs.guestID &&
        lhs.nonPushNotification == rhs.nonPushNotification &&
        lhs.lastName == rhs.language &&
        lhs.meta == rhs.meta &&
        lhs.systemProperties == rhs.systemProperties
}

extension UserModel.SystemProperties: Equatable {}

func ==(lhs: UserModel.SystemProperties, rhs: UserModel.SystemProperties) -> Bool {
    return lhs.isAdmin == rhs.isAdmin &&
        lhs.isMerchant == lhs.isMerchant &&
        lhs.lastLogin == rhs.lastLogin &&
        lhs.isActivated == rhs.isActivated
}


