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

/// This region plugin provides access to a collection of vatoms that are children of another vatom.
/// The 'inventory' region is much mor reliable, so if you know that your vatoms are owned by the current user,
/// use the inventory region with a filter rather.
///
/// To get an instance, call `DataPool.region("children", "parent-id")`
class VatomChildrenRegion: BLOCKvRegion {

    /// Plugin identifier.
    override class var id: String { return "children" }

    /// Parent ID.
    let parentID: String

    /// Constructor.
    required init(descriptor: Any) throws {

        // store ID
        parentID = descriptor as? String ?? ""

        // setup base class
        try super.init(descriptor: descriptor)

    }

    /// Our state key is the list of IDs.
    override var stateKey: String {
        return "children:" + self.parentID
    }

    /// Check if a region request matches our region.
    override func matches(id: String, descriptor: Any) -> Bool {
        return id == "children" && (descriptor as? String) == parentID
    }

    /// Load current state from the server.
    override func load() -> Promise<[String]?> {

        // pause websocket events
        self.pauseMessages()

        // fetch all pages recursively
        return self.fetch().map { dataObjects -> [String] in

            // add all objects
            self.add(objects: dataObjects)

            // return IDs
            return dataObjects.map { $0.id }

        }.ensure {

            // resume websocket events
            self.resumeMessages()

        }

    }

    /// Recursively fetch all pages of data from the server
    fileprivate func fetch(page: Int = 1, previousItems: [DataObject] = []) -> Promise<[DataObject]> {

        // create discover query
        let builder = DiscoverQueryBuilder()
        builder.setScope(scope: .parentID, value: parentID)
        builder.page = page
        builder.limit = 1000

        os_log("[%@] Fetching page %d, received %d items thus far.", log: .dataPool, type: .debug, typeName(self),
               page, previousItems.count)

        // create endpoint over void
        let endpoint: Endpoint<Void> = API.Generic.discover(builder.toDictionary())
        return BLOCKv.client.requestJSON(endpoint).then { json -> Promise<[DataObject]> in

            // extract payload
            guard let json = json as? [String: Any], let payload = json["payload"] as? [String: Any] else {
                throw NSError.init("Unable to load") //FIXME: Create a better error
            }

            // create list of items
            var items = previousItems

            // add vatoms to the list
            guard let vatomInfos = payload["results"] as? [[String: Any]] else { return Promise.value(items) }
            for vatomInfo in vatomInfos {

                // add data object
                let obj = DataObject()
                obj.type = "vatom"
                obj.id = vatomInfo["id"] as? String ?? ""
                obj.data = vatomInfo
                items.append(obj)

            }

            // add faces to the list
            guard let faces = payload["faces"] as? [[String: Any]] else { return Promise.value(items) }
            for face in faces {

                // add data object
                let obj = DataObject()
                obj.type = "face"
                obj.id = face["id"] as? String ?? ""
                obj.data = face
                items.append(obj)

            }

            // add actions to the list
            guard let actions = payload["actions"] as? [[String: Any]] else { return Promise.value(items) }
            for action in actions {

                // add data object
                let obj = DataObject()
                obj.type = "action"
                obj.id = action["name"] as? String ?? ""
                obj.data = action
                items.append(obj)

            }

            // if no more data, stop
            if vatomInfos.count == 0 {
                return Promise.value(items)
            }

            // done, get next page
            return self.fetch(page: page+1, previousItems: items)

        }

    }

}
