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

/*
 FIXME:
 Adding `id` as a case to this enum is useful for certain functions, like transfering a vatom
 where `id` is permitted.
 
 The drawback is that is make some apis ambigious. For example, login now permits a token type of
 `id` which does not make sense.
 
 This should potentially be split into two enums to avoid ambiguity.
 */

/// Models types of user tokens supported on the BLOCKv platform.
public enum UserTokenType: String, Codable {
    case phone = "phone_number"
    case email = "email"
    case id    = "id"
}

/// User token model.
public struct UserToken: Codable, Equatable {
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

    public func toDictionary() -> [String: Any] {
        return [
            "token": value,
            "token_type": type.rawValue
        ]
    }

}
