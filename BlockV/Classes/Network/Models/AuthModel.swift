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
