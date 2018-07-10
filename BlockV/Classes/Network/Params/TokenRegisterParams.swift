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

// MARK: - User Info

/// User properties parameters.
public struct UserInfo: Encodable {

    public var firstName: String?
    public var lastName: String?
    public var isNamePublic: Bool?
    public var password: String?
    public var birthday: String?
    public var isAvatarPublic: Bool?
    public var language: String?

    public init(firstName: String? = nil,
                lastName: String? = nil,
                isNamePublic: Bool? = true,
                password: String? = nil,
                birthday: String? = nil,
                isAvatarPublic: Bool? = true,
                language: String? = nil) {

        self.firstName = firstName
        self.lastName = lastName
        self.isNamePublic = isNamePublic
        self.password = password
        self.birthday = birthday
        self.isAvatarPublic = isAvatarPublic
        self.language = language
    }

    enum CodingKeys: String, CodingKey {
        case firstName      = "first_name"
        case lastName       = "last_name"
        case isNamePublic   = "name_public"
        case password       = "password"
        case birthday       = "birthday"
        case isAvatarPublic = "avatar_public"
        case language       = "language"
    }

}

extension UserInfo: DictionaryCodable {

    /// Returns a dictionary of all properties (with defaults for `nil` members).
    public func toDictionary() -> [String: Any] {
        return [
            "first_name": firstName ?? "",
            "last_name": lastName ?? "",
            "name_public": isNamePublic ?? true,
            "password": password ?? "",
            "birthday": birthday ?? "",
            "avatar_public": isAvatarPublic ?? true,
            "language": language ?? ""
        ]
    }

    /// Reuturns a dictionary of all non-nil members (empty strings are permitted).
    ///
    /// Useful for PATCH requests.
    public func toSafeDictionary() -> [String: Any] {
        var params: [String: Any] = [:]

        if let firstName = firstName {
            params["first_name"] = firstName
        }
        if let lastName = lastName {
            params["last_name"] = lastName
        }
        if let isNamePublic = isNamePublic {
            params["name_public"] = isNamePublic
        }
        if let password = password {
            params["password"] = password
        }
        if let birthday = birthday {
            params["birthday"] = birthday
        }
        if let isAvatarPublic = isAvatarPublic {
            params["avatar_public"] = isAvatarPublic
        }
        if let language = language {
            params["language"] = language
        }

        return params
    }

}

// MARK: - Protocols

/*
 Note:
 
 Conformance to DictionaryCodable is only required because Alamofire 4.X does not
 support Codable.
 
 Once support for Codable is implemented, DictionaryCodable conformance may be removed.
 
 See: https://github.com/Alamofire/Alamofire/issues/2181
 */

/// A type that conforms to the registration token parameter requirements and
/// has the ability to convert itself into a dictionary.
public typealias RegisterTokenParams = RegisterParams & DictionaryCodable

/// A type that conforms to the registration token parameter requirements.
public protocol RegisterParams { }

// MARK: - Register Params

/// Extend `UserToken` to conform to `RegisterParams`. This allows `UserToken` to be used 
extension UserToken: RegisterParams {}

/// Models the Oauth parameters needed for an oauth token registration.
///
/// - `userId`: Provider user id.
/// - `provider`: Provider name, e.g. "Facebook".
/// - `oauthToken`: Oauth token from the provider.
public struct OAuthTokenRegisterParams: RegisterParams {
    let userId: String // e.g. Facebook id
    let provider: String // e.g. FaceFacebook
    let oauthToken: String // e.g. oauth token

    public init(userId: String, provider: String, oauthToken: String) {
        self.userId = userId
        self.provider = provider
        self.oauthToken = oauthToken
    }

    enum CodingKeys: String, CodingKey {
        case userId      = "token"
        case provider    = "token_type"
        case authData    = "auth_data"
    }

    enum AuthDataKeys: String, CodingKey {
        case oauthToken = "auth_token"
    }

}

extension OAuthTokenRegisterParams: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(provider, forKey: .provider)

        var authData = container.nestedContainer(keyedBy: AuthDataKeys.self, forKey: .authData)
        try authData.encode(oauthToken, forKey: .oauthToken)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        userId = try values.decode(String.self, forKey: .userId)
        provider = try values.decode(String.self, forKey: .provider)

        let authData = try values.nestedContainer(keyedBy: AuthDataKeys.self, forKey: .authData)
        oauthToken = try authData.decode(String.self, forKey: .oauthToken)
    }

}

extension OAuthTokenRegisterParams: DictionaryCodable {
    public func toDictionary() -> [String: Any] {
        return [
            "token": userId,
            "token_type": provider,
            "auth_data": [
                "auth_token": oauthToken
            ]
        ]
    }
}

// MARK: - Convenience

/// Simple struct to represent a user's birthday.
//public struct Birthday {
//
//    let day: Int
//    let month: Int
//    let year: Int
//
//    /// Returns a dash separated representation of the birthday in the "yyyy-MM-dd" format.
//    ///
//    /// This is the format used when sending the birthday to the server.
//    public func dashSeparated() -> String {
//        return "\(year)-\(month)-\(day)"
//    }
//
//    enum CodingKeys: String, CodingKey {
//        case birthday
//    }
//
//}
//
//extension Birthday: Encodable {
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        let val = self.dashSeparated()
//        try container.encode(val, forKey: .birthday)
//    }
//
//}
