//
//  UserToken.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/02/28.
//

import Foundation

/// Models types of user tokens supported on the Blockv platform.
public enum UserTokenType: String, Codable {
    case phone = "phone_number"
    case email = "email"
}

/// User token model.
public struct UserToken: Codable {
    public let value: String       // e.g. joshsmith@bv.com
    public let type: UserTokenType // e.g. .email
    
    public init(value: String, type: UserTokenType) {
        self.value = value
        self.type = type
    }
    
    enum CodingKeys: String, CodingKey {
        case value = "token"
        case type = "token_type"
    }
}

extension UserToken: DictionaryCodable {
    
    public func toDictionary() -> [String : Any] {
        return [
            "token" : value,
            "token_type" : type.rawValue
        ]
    }
    
}

// MARK: - Equatable

// Every value type should be equatable.
extension UserToken: Equatable {}

public func ==(lhs: UserToken, rhs: UserToken) -> Bool {
    return lhs.value == rhs.value &&
    lhs.type == rhs.type
}
