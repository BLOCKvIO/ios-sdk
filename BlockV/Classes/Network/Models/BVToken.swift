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

/// BlockV token model.
///
/// Used to represent a refresh or access token.
struct BVToken: Codable, Equatable {
    let token: String
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case token = "token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

/// BLOCKv refresh token response
struct RefreshModel: Decodable {
    let accessToken: BVToken

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
