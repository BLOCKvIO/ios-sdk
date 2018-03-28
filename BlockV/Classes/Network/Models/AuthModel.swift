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

/// Types conforming to OAuthTokenModel should have accessors for `access` and `refresh` tokens
protocol OAuthTokenModel {
    var accessToken: BVToken { get }
    var refreshToken: BVToken { get }
}

/// Auth response model.
///
/// This model is valid for both login and register responses.
struct AuthModel: Decodable, OAuthTokenModel {
    
    var user: UserModel
    let assetProviders: [AssetProvider]
    let accessToken: BVToken
    let refreshToken: BVToken
    
    enum CodingKeys: String, CodingKey {
        case user           = "user"
        case assetProviders = "asset_provider"
        case accessToken    = "access_token"
        case refreshToken   = "refresh_token"
    }

}

// MARK: Equatable

extension AuthModel: Equatable {}

func ==(lhs: AuthModel, rhs: AuthModel) -> Bool {
    return lhs.user == rhs.user &&
        lhs.assetProviders == rhs.assetProviders &&
        lhs.accessToken == rhs.accessToken &&
        lhs.refreshToken == rhs.refreshToken
}
