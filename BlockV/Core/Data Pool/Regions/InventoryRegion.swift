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

/*
 Issues
 2. Dependecy inject session info (don't rely on static DataPool.sessionInfo)
 3. Convert discover to inventory call (server dependent).
 4. Convert request to auth-lifecylce participating requests.
 */

/// This region plugin provides access to the current user's inventory.
///
/// Two primary functions:
/// 1. Overrides load (to fetch all object from the server).
/// 2. Processing 'inventory' messages.
///    > Importanly, for vatom additions, this pauses the message processing, fetches the vatom, and only resumes the
///    message processing.
class InventoryRegion: BLOCKvRegion {

    /// Plugin identifier.
    override class var id: String { return "inventory" }

    /// Constructor.
    required init(descriptor: Any) throws {
        try super.init(descriptor: descriptor)

        // make sure we have a valid current user
        guard let userID = DataPool.sessionInfo["userID"] as? String, !userID.isEmpty else {
            throw NSError("You cannot query the inventory region without being logged in.")
        }

    }

    /// Current user ID.
    let currentUserID = DataPool.sessionInfo["userID"] as? String ?? ""

    /// Our state key is the current user's Id.
    override var stateKey: String {
        return "inventory:" + currentUserID
    }

    /// Returns `true` if this region matches the `id` and `descriptor`.
    ///
    /// There should only be one inventory region.
    override func matches(id: String, descriptor: Any) -> Bool {
        return id == "inventory"
    }

    /// Called when session info changes. This should trigger a clean up process since the region may no longer be
    /// valid.
    override func onSessionInfoChanged(info: Any?) {
        // shut down this region if the current user changes.
        self.close()
    }

    /// Load current state from the server.
    override func load() -> Promise<[String]?> {

        // pause websocket events
        self.pauseMessages()

        // fetch all pages recursively
        return self.fetch().ensure {

            // resume websocket events
            self.resumeMessages()

        }

    }

    /// Fetches all objects from the server.
    ///
    /// Recursivly pages through the server's pool until all object have been found.
    fileprivate func fetch(page: Int = 1, previousItems: [String] = []) -> Promise<[String]?> {

        // stop if closed
        if closed {
            return Promise.value(previousItems)
        }

        // execute it
        printBV(info: "[DataPool > InventoryRegion] Loading page \(page), got \(previousItems.count) items so far...")

        // build raw request
        let endpoint = API.Raw.getInventory(parentID: "*", page: page)

        return BLOCKv.client.requestJSON(endpoint).then { json -> Promise<[String]?> in

            guard let json = json as? [String: Any], let payload = json["payload"] as? [String: Any] else {
                throw NSError.init("Unable to load") //FIXME: Create a better error
            }

            // create list of items
            var ids = previousItems

            // parse out data objects
            guard let items = self.parseDataObject(from: payload) else {
                return Promise.value(ids)
            }
            // append new ids
            ids.append(contentsOf: items.map { $0.id })

            // add data objects
            self.add(objects: items)

            // if no more data, stop
            if items.count == 0 {
                return Promise.value(ids)
            }

            // done, get next page
            return self.fetch(page: page + 1, previousItems: ids)

        }

    }

    /// Called on Web socket message.
    ///
    /// Allows super to handle 'state_update', then goes on to process 'inventory' events.
    /// Message process is paused for 'inventory' events which indicate a vatom was added. Since the vatom must
    /// be fetched from the server.
    override func processMessage(_ msg: [String: Any]) {
        super.processMessage(msg)

        // get info
        guard let msgType = msg["msg_type"] as? String else { return }
        guard let payload = msg["payload"] as? [String: Any] else { return }
        guard let oldOwner = payload["old_owner"] as? String else { return }
        guard let newOwner = payload["new_owner"] as? String else { return }
        guard let vatomID = payload["id"] as? String else { return }
        if msgType != "inventory" {
            return
        }

        // check if this is an incoming or outgoing vatom
        if oldOwner == self.currentUserID && newOwner != self.currentUserID {

            // vatom is no longer owned by us
            self.remove(ids: [vatomID])

        } else if oldOwner != self.currentUserID && newOwner == self.currentUserID {

            // vatom is now our inventory
            // pause this instance's message processing and fetch vatom payload
            self.pauseMessages()

            let endpoint = API.Raw.getVatoms(withIDs: [vatomID])
            BLOCKv.client.request(endpoint).done { data in

                // convert
                guard
                    let object = try? JSONSerialization.jsonObject(with: data),
                    let json = object as? [String: Any],
                    let payload = json["payload"] as? [String: Any] else {
                    throw NSError.init("Unable to load") //FIXME: Create a better error
                }

                // parse out objects
                guard let items = self.parseDataObject(from: payload) else {
                    throw NSError.init("Unable to parse data") //FIXME: Create a better error
                }

                // add new objects
                self.add(objects: items)

            }.catch { error in
                printBV(error: "[InventoryRegion] Unable to fetch inventory. \(error.localizedDescription)")
            }.finally {
                // resume WebSocket processing
                self.resumeMessages()
            }

        } else {

            // logic error, old owner and new owner cannot be the same
            printBV(error: "[InventoryRegion] Logic error in WebSocket message, old_owner and new_owner shouldn't be the same: \(vatomID)")

        }

    }

}
