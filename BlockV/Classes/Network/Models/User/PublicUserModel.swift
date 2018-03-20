//
//  PublicUser.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/02/23.
//

import Foundation

/// Public user response model.
public struct PublicUserModel: Codable {
    
    public let id : String
    public let meta : MetaModel
    public let properties : Properties
    
    public struct Properties : Codable {
        public let firstName : String
        public let lastName : String
        
        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
        }
    }
    
}

// MARK: - Equatable

// Every value type should be equatable.
extension PublicUserModel: Equatable {}

public func ==(lhs: PublicUserModel, rhs: PublicUserModel) -> Bool {
    return lhs.id == rhs.id &&
    lhs.meta == rhs.meta &&
    lhs.properties == rhs.properties
}

// Every value type should be equatable.
extension PublicUserModel.Properties: Equatable {}

public func ==(lhs: PublicUserModel.Properties, rhs: PublicUserModel.Properties) -> Bool {
    return lhs.firstName == rhs.firstName &&
    lhs.lastName == rhs.lastName
}
