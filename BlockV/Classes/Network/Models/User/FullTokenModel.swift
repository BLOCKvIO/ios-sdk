//
//  FullTokenModel.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/02/22.
//

import Foundation

/// Full token response model.
public struct FullTokenModel: Codable {
    
    public let id: String
    public let meta: MetaModel
    public let properties: Properties
    
    public struct Properties: Codable {
        public let appId: String
        public let isConfirmed: Bool
        public let isDefault: Bool
        public let otp: String
        public let token: String
        public let tokenType: String
        public let userId: String
        public let verifyCode: String
        public let verifyCodeExpires: Date
        
        enum CodingKeys: String, CodingKey {
            case appId             = "app_id"
            case isConfirmed       = "confirmed"
            case isDefault         = "is_default"
            case otp               = "otp"
            case token             = "token"
            case tokenType         = "token_type"
            case userId            = "user_id"
            case verifyCode        = "verify_code"
            case verifyCodeExpires = "verify_code_expires"
        }
    }

}

// MARK: - Equatable

// Every value type should be equatable.
extension FullTokenModel: Equatable {}

public func ==(lhs: FullTokenModel, rhs: FullTokenModel) -> Bool {
    return lhs.id == rhs.id &&
    lhs.meta == rhs.meta &&
    lhs.properties == rhs.properties
}

// Every value type should be equatable.
extension FullTokenModel.Properties: Equatable {}

public func ==(lhs: FullTokenModel.Properties, rhs: FullTokenModel.Properties) -> Bool {
    return lhs.appId == rhs.appId &&
    lhs.isConfirmed == rhs.isConfirmed &&
    lhs.isDefault == rhs.isDefault &&
    lhs.otp == rhs.otp &&
    lhs.token == rhs.token &&
    lhs.tokenType == rhs.tokenType &&
    lhs.userId == rhs.userId &&
    lhs.verifyCode == rhs.verifyCode &&
    lhs.verifyCodeExpires == rhs.verifyCodeExpires
}
