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

import os
import Foundation
import PromiseKit
import MapKit

/*
 # Notes:
 
 1. Static vs singleton
    Static is problematic for testing. It may be better to have a singleton object.
 2. DataPool should have an array of BLOCKvRegion - no need to have Region
 3. Make sure data pool works for changing user sesssion (non-parallel).
 4. Put some thought into creating isolated instances of the SDK - to allow for unit testing.
 5. onObjectAdded(), onObjectUpdated() is fired for every vatom and seems to be causing an inventory reload.
 */

/// Data Pool plugin (region classes) must be pre-registered.
/// Region instances are created on-demand.
/// Regions are loaded from disk cache.
public final class DataPool {
    
    enum SessionError: Error {
        case currentUserPermission
    }

    /// List of available plugins, i.e. region classes.
    internal static let plugins: [Region.Type] = [
        InventoryRegion.self,
        VatomChildrenRegion.self,
        VatomIDRegion.self,
        GeoPosRegion.self
    ]

    /// List of active regions.
    internal static var regions: [Region] = []

    /// Session data. Stores the current user ID, or anything like that that the host uses to identify a session.
    internal static var sessionInfo: [String: Any] = [:] {
        didSet {
            // notify regions
            for reg in regions {
                reg.onSessionInfoChanged(info: sessionInfo)
            }
        }
    }
    
    public static var currentUserId: String {
        return sessionInfo["userID"] as? String ?? ""
    }

    /// Fetches or creates a named data region.
    ///
    /// - Parameters:
    ///   - id: The region ID. This is the ID of the region plugin.
    ///   - descriptor: Any data required by the region plugin.
    /// - Returns: A Region.
    internal static func region(id: String, descriptor: Any) -> Region {

        // find existing region
        if let region = regions.first(where: { $0.matches(id: id, descriptor: descriptor) }) {
            return region
        }

        // not found, create a new region. find region plugin
        guard let regionPlugin = plugins.first(where: { $0.id == id }) else {
            fatalError("[DataPool] No region plugin matches ID: \(id)")
        }

        // create and store region instance.
        guard let region = try? regionPlugin.init(descriptor: descriptor) else {
            fatalError("[DataPool] Region can't be created in this context")
            // TODO: Better error handling? This shouldn't normally happen though.
        }
        regions.append(region)

        // load region from disk
        region.loadFromCache().recover { err -> Void in

            // unable to load from disk
            os_log("[%@] Unable to load region state from disk: %@", log: .dataPool, type: .error,
                   typeName(self), err.localizedDescription)

        }.then { _ -> Guarantee<Void> in

            // start sync'ing region data with the server
            return region.synchronize()

        }.catch { err in

            // unable to load from network either!
            os_log("[%@] Unable to load region state from network: %@", log: .dataPool, type: .error,
                   typeName(self), err.localizedDescription)

        }

        // return new region
        return region

    }

    /// Removes the specified region. This is called by Region.close(), it must not be called by anything else.
    ///
    /// - Parameter region: The region to remove
    static func removeRegion(region: Region) {

        // remove region
        regions = regions.filter { $0 !== region }

    }

    /// Clear out the session info.
    static func clear() {
        self.sessionInfo = [:]
    }

}

extension DataPool {

    /*
     Convenience functions for fetching/creating regions. Only the abstract `Region` type is returned.
     */

    /// Returns the global inventory region.
    public static func inventory() -> Region {
        return DataPool.region(id: InventoryRegion.id, descriptor: "")
    }

    /// Returns the vatom region for the specified identifier.
    public static func vatom(id: String) -> Region {
        return DataPool.region(id: VatomIDRegion.id, descriptor: [id])
    }

    /// Returns the children region for the specifed parent identifier.
    public static func children(parentID: String) -> Region {
        return DataPool.region(id: VatomChildrenRegion.id, descriptor: parentID)
    }

    /// Returns the geo pos region for the specifed coordinate region.
    public static func geoPos(region: MKCoordinateRegion) -> Region {
        return DataPool.region(id: GeoPosRegion.id, descriptor: region)
    }

}
