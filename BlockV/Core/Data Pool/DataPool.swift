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
import PromiseKit

///
///
/// Data Pool plugin (region classes) must be pre-registered.
/// Region instances are created on-demand.
/// Regions are loaded from disk cache.
public final class DataPool {

    /// List of available plugins, i.e. region classes.
    static let plugins: [Region.Type] = [
//        InventoryRegion.self
//        VatomIDRegion.self,
//        VatomChildrenRegion.self,
//        GeoPosRegion.self
    ]

    /// List of active regions
    static var regions: [Region] = []

    /// Session data. Stores the current user ID, or anything like that that the host uses to identify a session.
    static var sessionInfo: [String: Any] = [:] {
        didSet {

            // Notify regions
            for reg in regions {
                reg.onSessionInfoChanged(info: sessionInfo)
            }

        }
    }

    /// Fetches or creates a named data region.
    ///
    /// - Parameters:
    ///   - id: The region ID. This is the ID of the region plugin.
    ///   - descriptor: Any data required by the region plugin.
    /// - Returns: A Region.
    public static func region(id: String, descriptor: Any) -> Region {

        // Find existing region
        if let region = regions.first(where: { $0.matches(id: id, descriptor: descriptor) }) {
            return region
        }

        // We need to create a new region. Find region plugin
        guard let regionPlugin = plugins.first(where: { $0.ID == id }) else {
            fatalError("[DataPool] No region plugin matches ID: \(id)")
        }

        // Create and store region instance.
        guard let region = try? Region.init(descriptor: descriptor) else {
            fatalError("[DataPool] Region can't be created in this context")
            // TODO: Better error handling? This shouldn't normally happen though.
        }
        regions.append(region)

        // Load region from disk
        region.loadFromCache().recover { err -> Void in

            // Unable to load from disk
            printBV(error: "[DataPool] Unable to load region state from disk. " + err.localizedDescription)

        }.then { _ -> Guarantee<Void> in

            // Start sync'ing region data with the server
            return region.synchronize()

        }.catch { err in

            // Unable to load from network either!
            printBV(error: "[DataPool] Unable to load region state from network. " + err.localizedDescription)

        }

        // Return new region
        return region

    }

    /// Removes the specified region. This is called by Region.close(), it must not be called by anything else.
    ///
    /// - Parameter region: The region to remove
    static func removeRegion(region: Region) {

        // Remove region
        regions = regions.filter { $0 !== region } // array no longer keeps a strong ref to the region

    }

}
