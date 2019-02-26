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

/// This region plugin provides access to the current user's inventory.
class InventoryRegion : BLOCKvRegion {

    /// Plugin ID
    override class var ID : String { return "inventory" }

    /** Constructor */
    required init(descriptor: Any) throws {
        try super.init(descriptor: descriptor)

        // Make sure we have a valid current user
        guard let userID = DataPool.sessionInfo["userID"] as? String, !userID.isEmpty else {
            throw NSError("You cannot query the inventory region without being logged in.")
        }

    }

    /// Current user ID
    let currentUserID = DataPool.sessionInfo["userID"] as? String ?? ""

    /// Our state key is the current user's ID
    override var stateKey : String {
        return "inventory:" + currentUserID
    }

    /// There should only be one inventory region
    override func matches(id : String, descriptor : Any) -> Bool {
        return id == "inventory"
    }

    /// Shut down this region if the current user changes
    override func onSessionInfoChanged(info : Any?) {
        self.close()
    }

    /** Load current state from the server */
    override func load() -> Promise<[String]?> {

        // Pause websocket events
        self.pauseMessages()

        // Fetch all pages recursively
        return self.fetch().ensure {

            // Resume websocket events
            self.resumeMessages()

        }

    }

    /// Recursively fetch all pages of data from the server
    fileprivate func fetch(page : Int = 1, previousItems : [String] = []) -> Promise<[String]?> {

        // Stop if closed
        if closed {
            return Promise(value: previousItems)
        }

//        // Create discover query
//        let filter = VatomDiscoverFilter()
//        filter.ownedVatomsOnly = true
//        filter.page = page
//        filter.limit = 1000

        // create discover query
        let builder = DiscoverQueryBuilder()
        builder.setScopeToOwner()
        //TODO: set page & limit

        // Execute it
        printBV(info: "[DataPool > InventoryRegion] Loading page \(page), got \(previousItems.count) items so far...")

        // build raw request
        let endpoint = API.raw.discover(builder.toDictionary())
        BLOCKv.client.request(endpoint).then { data -> Promise<[String]?> in

        }

        BLOCKv.client.request(endpoint) { (data, error) in



        }

        return Request2.post(endpoint: "/vatom/discover", payload: builder.toDictionary()).then { data -> Promise<[String]?> in

            // Create list of items
            var items : [DataObject] = []
            var ids = previousItems

            // Add vatoms to the list
            guard let vatomInfos = data["results"] as? [[String:Any]] else { return Promise(value: ids) }
            for vatomInfo in vatomInfos {

                // Add data object
                let obj = DataObject()
                obj.type = "vatom"
                obj.id = vatomInfo["id"] as? String ?? ""
                obj.data = vatomInfo
                items.append(obj)
                ids.append(obj.id)

            }

            // Add faces to the list
            guard let faces = data["faces"] as? [[String:Any]] else { return Promise(value: ids) }
            for face in faces {

                // Add data object
                let obj = DataObject()
                obj.type = "face"
                obj.id = face["id"] as? String ?? ""
                obj.data = face
                items.append(obj)
                ids.append(obj.id)

            }

            // Add actions to the list
            guard let actions = data["actions"] as? [[String:Any]] else { return Promise(value: ids) }
            for action in actions {

                // Add data object
                let obj = DataObject()
                obj.type = "action"
                obj.id = action["name"] as? String ?? ""
                obj.data = action
                items.append(obj)
                ids.append(obj.id)

            }

            // Add data objects
            self.add(objects: items)

            // If no more data, stop
            if vatomInfos.count == 0 {
                return Promise(value: ids)
            }

            // Done, get next page
            return self.fetch(page: page + 1, previousItems: ids)

        }

    }

    /// Called on WebSocket message.
    override func processMessage(_ msg: [String:Any]) {
        super.processMessage(msg)

        // Get info
        guard let msg_type = msg["msg_type"] as? String else { return }
        guard let payload = msg["payload"] as? [String:Any] else { return }
        guard let old_owner = payload["old_owner"] as? String else { return }
        guard let new_owner = payload["new_owner"] as? String else { return }
        guard let vatomID = payload["id"] as? String else { return }
        if msg_type != "inventory" {
            return
        }

        // Check if this is an incoming or outgoing vatom
        if (old_owner == self.currentUserID && new_owner != self.currentUserID) {

            // Vatom is no longer owned by us
            self.remove(ids: [vatomID])

        } else if (old_owner != self.currentUserID && new_owner == self.currentUserID) {

            // Vatom is now our inventory! Pause WebSocket and fetch vatom payload
            self.pauseMessages()
            Request2.post(endpoint: "/user/vatom/get", payload: [ "ids": [vatomID] ]).then { data -> Void in

                // Add vatom to new objects list
                var items : [DataObject] = []

                // Add vatoms to the list
                guard let vatomInfos = data["vatoms"] as? [[String:Any]] else { return }
                for vatomInfo in vatomInfos {

                    // Add data object
                    let obj = DataObject()
                    obj.type = "vatom"
                    obj.id = vatomInfo["id"] as? String ?? ""
                    obj.data = vatomInfo
                    items.append(obj)

                }

                // Add faces to the list
                guard let faces = data["faces"] as? [[String:Any]] else { return }
                for face in faces {

                    // Add data object
                    let obj = DataObject()
                    obj.type = "face"
                    obj.id = face["id"] as? String ?? ""
                    obj.data = face
                    items.append(obj)

                }

                // Add actions to the list
                guard let actions = data["actions"] as? [[String:Any]] else { return }
                for action in actions {

                    // Add data object
                    let obj = DataObject()
                    obj.type = "action"
                    obj.id = action["name"] as? String ?? ""
                    obj.data = action
                    items.append(obj)

                }

                // Add new objects
                self.add(objects: items)

                // Notify vatom received
                guard let vatom = self.get(id: vatomInfos[0]["id"] as? String ?? "") as? Vatom else {
                    printBV(error: "[DataPool > InventoryRegion] Couldn't process incoming vatom")
                    return
                }

                // Notify incoming
                vatom.onReceived(from: VatomUser.withID(old_owner), presentationInfo: [:], triggeringAction: payload["action_name"] as? String)

                }.always { () -> Void in

                    // Resume WebSocket processing
                    self.resumeMessages()

            }

        } else {

            // Logic error, old owner and new owner cannot be the same
            printBV(error: "[DataPool > BVWebSocketRegion] Logic error in WebSocket message, old_owner and new_owner shouldn't be the same: \(vatomID)")

        }

    }

}
