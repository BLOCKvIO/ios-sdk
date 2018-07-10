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

protocol CredentialManager {

    static func clear()

    static var refreshToken: BVToken? { get }

    static func saveRefreshToken(_ token: BVToken)

    static var assetProviders: [AssetProviderModel] { get }

    static func saveAssetProviders(_ providers: [AssetProviderModel])

}

/// This class is used to provided a storage layer for BlockV credentials including:
/// - OAuth2 refresh token
/// - Asset providers
internal class CredentialStore: CredentialManager {

    // MARK: - General

    /// Persistance keys
    fileprivate static let refreshTokenKey   = "com.blockv.credentials.refreshToken"
    fileprivate static let assetProvidersKey = "com.blockv.credentials.assetProviders"

    /// Removes all credentials from local storage.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: assetProvidersKey)
    }

    // MARK: - OAuth2

    /// Returns the refresh token from local storage.
    static var refreshToken: BVToken? {
        // extract data
        guard let data = UserDefaults.standard.data(forKey: refreshTokenKey) else {
            return nil
        }
        // decode to `BVToken`
        return try? JSONDecoder().decode(BVToken.self, from: data)
    }

    /// Saves the refresh token to local storage.
    ///
    /// This is an overwrite operation.
    static func saveRefreshToken(_ token: BVToken) {
        // encode to data (ineffient, but inconsequential)

        // FIXME: How to handle this force unwrap?
        let data = try! JSONEncoder().encode(token)
        // save the data
        UserDefaults.standard.set(data, forKey: refreshTokenKey)
    }

    /// Removes the refresh token from local storage.
    static func removeRefreshToken() {
        // remove the data blob
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
    }

    // MARK: - Asset Provider

    /// Returns the asset providers from local storage.
    static var assetProviders: [AssetProviderModel] {
        // extract data
        guard let data = UserDefaults.standard.data(forKey: assetProvidersKey) else {
            return []
        }
        // decode to `AssetProvider`
        return (try? JSONDecoder().decode([AssetProviderModel].self, from: data)) ?? []
    }

    /// Saves the asset providers to local storage.
    ///
    /// This is an overwrite operation.
    static func saveAssetProviders(_ providers: [AssetProviderModel]) {
        // encode to data (ineffient, but inconsequential)

        // FIXME: How to handle this force unwrap?
        let data = try! JSONEncoder().encode(providers)
        // save the data
        UserDefaults.standard.set(data, forKey: assetProvidersKey)
    }

}
