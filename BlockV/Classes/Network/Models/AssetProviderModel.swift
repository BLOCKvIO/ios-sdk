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

typealias URLEncoder = (_ url: URL, _ assetProviders: [AssetProviderModel]) -> URL

/// A type that can encode it's URLs for a designated asset provider.
protocol AssetProviderEncodable {
    
    /// Option 1
    ///
    /// Types adopting this protocol should encode each of their urls using the provided encoder.
    mutating func encodeEachURL(using encoder: URLEncoder, assetProviders: [AssetProviderModel])
    
//    /// Option 2
//    ///
//    /// Encodes the supplied URL with underlying asset providers.
//    func encodeURL(_ url: URL) -> URL
//
//    /// Option 3
//    ///
//    /// Encodes the supplied URL with the supplied asset providers.
//    func encodeURL(_ url: URL, assetProviders: [AssetProvider]) -> URL

}

//extension AssetProviderEncodable {
//
//    /*
//     Option 2
//     Pros:
//     - Can be used anywhere.
//     Cons:
//     - Dependecy injection fail. Pulls from a static credential store that could be in
//     any state. This is not clean.
//     */
//
//    func encodeURL(_ url: URL) -> URL {
//        let assetProviders = CredentialStore.assetProviders
//        let provider = assetProviders.first(where: { $0.isProviderForURL(url) })
//        return provider?.encodedURL(url) ?? url
//    }
//
//    /*
//     Option 3
//     Pros:
//     - Asset providers are injected. This allows control of the input.
//     Cons:
//     - Asset providers will be needed at the call site.
//     */
//
//    func encodeURL(_ url: URL, assetProviders: [AssetProvider]) -> URL {
//        let provider = assetProviders.first(where: { $0.isProviderForURL(url) })
//        return provider?.encodedURL(url) ?? url
//    }
//
//}

struct AssetProviderModel: Codable, Equatable {
    
    let name: String
    let uri: URL
    let type: String
    
    /// The descriptor contains a dictionary whose keys correspond to resource url query keys
    /// and whose values correspond to resource url query params.
    let descriptor: [String : String]
    
    /// Returns an array of `URLQueryItem` respresenting the descriptor.
    var queryItems: [URLQueryItem] {
        return descriptor.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    /// Boolean indicating whether this asset provider is the URL's designated
    /// asset provider.
    func isProviderForURL(_ url: URL) -> Bool {
        return url.absoluteString.hasPrefix(uri.absoluteString)
    }
    
    /// Returns a `URL` encoded with the asset providers query params.
    ///
    /// Returns `nil` if the the URL cannot be constructed or if the asset provider is not the
    /// URL's designated asset provider.
    func encodedURL(_ url: URL) -> URL? {
        
        // Example: <url>?Key-Pair-Id=<key-pair-id>&Signature=<signature>&Policy=<policy>
        
        guard isProviderForURL(url) else { return nil }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = self.queryItems
        return components?.url
        
    }
    
}
