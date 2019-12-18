//
//  BLOCKv AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BLOCKv SDK License (the "License"); you may not use this file or
//  the BLOCKv SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BLOCKv SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import Foundation

public struct OAuthTokenExchangeModel: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expriesIn: Double
    let scope: String

    enum CodingKeys: String, CodingKey {
        case accessToken    = "access_token"
        case refreshToken   = "refresh_token"
        case tokenType      = "token_type"
        case expriesIn      = "expires_in"
        case scope          = "scope"
    }
}
