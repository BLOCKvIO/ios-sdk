//
//  BVToken.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/02/28.
//

import Foundation

/// BlockV token model.
///
/// Used to represent a refresh or access token.
struct BVToken: Codable {
    let token: String
    let tokenType: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case token = "token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

// MARK: - Equatable

// Every value type should be equatable.
extension BVToken: Equatable {}

func ==(lhs: BVToken, rhs: BVToken) -> Bool {
    return lhs.token == rhs.token &&
    lhs.tokenType == rhs.tokenType &&
    lhs.expiresIn == rhs.expiresIn
}

/// Blockv refresh token response
struct RefreshModel: Decodable {
    let accessToken: BVToken
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
