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

// MARK: - Protocols

/*
 Note:
 
 Conformance to DictionaryCodable is only required because Alamofire 4.X does not
 support Codable.
 
 Once support for Codable is implemented, DictionaryCodable conformance may be removed.
 
 See: https://github.com/Alamofire/Alamofire/issues/2181
 */

/// A type that conforms to the login token parameter requirements and
/// has the ability to convert itself into a dictionary.
public typealias LoginTokenParams = LoginParams & DictionaryCodable

/// A type that conforms to the login token parameter requirements.
public protocol LoginParams {}

// MARK: - Login Guest Id

public struct GuestIdLoginParams: LoginParams {
    public let id: String

    public init(id: String) {
        self.id = id
    }

    enum CodingKeys: String, CodingKey {
        case id = "token"
    }
}

extension GuestIdLoginParams: DictionaryCodable {

    public func toDictionary() -> [String: Any] {
        return [
            "token": id,
            "token_type": "guest_id"
        ]
    }

}

// MARK: - Login User Token

/// User token parameters for login.
public struct UserTokenLoginParams: LoginParams {
    let userToken: UserToken
    let password: String

    public init(value: String, type: UserTokenType, password: String) {
        self.userToken = UserToken(value: value, type: type)
        self.password = password
    }

    enum CodingKeys: String, CodingKey {
        case token = "token"
        case type = "token_type"
        case authData = "auth_data"
    }

    enum AuthDataKeys: String, CodingKey {
        case password
    }

}

extension UserTokenLoginParams: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userToken.value, forKey: .token)
        try container.encode(userToken.type, forKey: .type)

        var authData = container.nestedContainer(keyedBy: AuthDataKeys.self, forKey: .authData)
        try authData.encode(password, forKey: .password)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let value = try values.decode(String.self, forKey: .token)
        let type = try values.decode(UserTokenType.self, forKey: .type)
        userToken = UserToken(value: value, type: type)

        let authData = try values.nestedContainer(keyedBy: AuthDataKeys.self, forKey: .authData)
        password = try authData.decode(String.self, forKey: .password)
    }
}

extension UserTokenLoginParams: DictionaryCodable {

    public func toDictionary() -> [String: Any] {
      return  [
            "token": userToken.value,
            "token_type": userToken.type.rawValue,
            "auth_data": [
                "password": password
            ]
        ]
    }

}

// MARK: - Login OAuth Params

/// OAuth token paramters for login.
public struct OAuthTokenLoginParams: LoginParams {

    let provider: String // e.g. Facebook
    let oauthToken: String // oauth token

    public init(provider: String, oauthToken: String) {
        self.provider = provider
        self.oauthToken = oauthToken
    }

    enum CodingKeys: String, CodingKey {
        case provider = "token_type"
        case authData = "auth_data"
    }

    enum AuthDataKeys: String, CodingKey {
        case oauthToken = "oauth_token" // NB: Subtle difference to the register token.
    }

}

extension OAuthTokenLoginParams: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(provider, forKey: .provider)

        var authData = container.nestedContainer(keyedBy: AuthDataKeys.self, forKey: .authData)
        try authData.encode(oauthToken, forKey: .oauthToken)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        provider = try values.decode(String.self, forKey: .provider)

        let authData = try values.nestedContainer(keyedBy: AuthDataKeys.self, forKey: .authData)
        oauthToken = try authData.decode(String.self, forKey: .oauthToken)
    }

}

extension OAuthTokenLoginParams: DictionaryCodable {

    public func toDictionary() -> [String: Any] {
        return [
            "token_type": provider,
            "auth_data": [
                "oauth_token": oauthToken
            ]
        ]
    }

}
