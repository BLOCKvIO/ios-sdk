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
import PromiseKit

/// This region plugin provides access to a collection of vatoms identified by their IDs.
/// The 'inventory' region is much more reliable, so if you know that your vatoms are owned by the current user,
/// use the inventory region with a filter rather.
///
/// TODO: Retry a few times
///
/// To get an instance, call `DataPool.region("ids", ["id1", "id2"])`
class VatomIDRegion: BLOCKvRegion {

    /// Plugin identifier.
    override class var id: String { return "ids" }

    /// IDs being fetched in this region.
    let ids: [String]

    /// Constructor.
    required init(descriptor: Any) throws {

        // store IDs
        ids = descriptor as? [String] ?? []

        // setup base class
        try super.init(descriptor: descriptor)

    }

    /// Our state key is the list of IDs.
    override var stateKey: String {
        return "ids:" + self.ids.joined(separator: ",")
    }

    /// Check if a region request matches our region.
    override func matches(id: String, descriptor: Any) -> Bool {

        // check all filters match
        if id != "ids" { return false }
        guard let otherIds = descriptor as? [String] else { return false }
        // check ids match
        return self.ids == otherIds

    }

    /// Load current state from the server.
    override func load() -> Promise<[String]?> {

        // pause websocket events
        self.pauseMessages()

        let endpoint: Endpoint<Void> = API.Generic.getVatoms(withIDs: ids)
        return BLOCKv.client.requestJSON(endpoint).then { json -> Promise<[String]?> in

            guard let json = json as? [String: Any], let payload = json["payload"] as? [String: Any] else {
                throw NSError.init("Unable to load") //FIXME: Create a better error
            }

            // parse items
            guard let items = self.parseDataObject(from: payload) else {
                throw NSError.init("Unable to parse data") //FIXME: Create a better error
            }

            // add all objects
            self.add(objects: items)

            // return IDs
            let ids = items.map { $0.id }

            return Promise.value(ids)

        }.ensure {

            // resume websocket events
            self.resumeMessages()

        }

    }

}
