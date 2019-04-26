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

public struct TemporaryOAuthTokenExchangeModel: Decodable, Equatable {

    let accessToken: BVToken
    let refreshToken: BVToken
    
    enum CodingKeys: String, CodingKey {
        case accessToken    = "access_token"
        case refreshToken   = "refresh_token"
    }
    
}

public struct OAuthTokenExchangeModel: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String? //FIXME: Make non-optional when server is updated
    let expriesIn: Double? //FIXME: Make non-optional when server is updated
    let scope: String? //FIXME: Make non-optional when server is updated

    enum CodingKeys: String, CodingKey {
        case accessToken    = "access_token"
        case refreshToken   = "refresh_token"
        case tokenType      = "token_type"
        case expriesIn      = "expires_in"
        case scope          = "scope"
    }
}
