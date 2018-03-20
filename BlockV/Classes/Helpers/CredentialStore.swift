//
//  CredentialStore.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/03/06.
//

import Foundation

protocol CredentialManager {
    
    static func clear()
    
    static var refreshToken: BVToken? { get }
    
    static func saveRefreshToken(_ token: BVToken)
    
    static var assetProviders: [AssetProvider] { get }
    
    static func saveAssetProviders(_ providers: [AssetProvider])
    
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
        get {
            // extract data
            guard let data = UserDefaults.standard.data(forKey: refreshTokenKey) else {
                return nil
            }
            // decode to `BVToken`
            return try? JSONDecoder().decode(BVToken.self, from: data)
        }
    }
    
    /// Saves the refresh token to local storage.
    ///
    /// This is an overwirte operation.
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
    static var assetProviders: [AssetProvider] {
        get {
            // extract data
            guard let data = UserDefaults.standard.data(forKey: assetProvidersKey) else {
                return []
            }
            // decode to `AssetProvider`
            return (try? JSONDecoder().decode([AssetProvider].self, from: data)) ?? []
        }
    }
    
    /// Saves the asset providers to local storage.
    ///
    /// This is an overwirte operation.
    static func saveAssetProviders(_ providers: [AssetProvider]) {
        // encode to data (ineffient, but inconsequential)
        
        // FIXME: How to handle this force unwrap?
        let data = try! JSONEncoder().encode(providers)
        // save the data
        UserDefaults.standard.set(data, forKey: assetProvidersKey)
    }
    
}
