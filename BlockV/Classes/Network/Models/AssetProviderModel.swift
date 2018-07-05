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

struct AssetProviderModel: Codable, Equatable {

    let name: String
    let uri: URL
    let type: String

    /// The descriptor contains a dictionary whose keys correspond to resource url query keys
    /// and whose values correspond to resource url query params.
    let descriptor: [String: String]

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
