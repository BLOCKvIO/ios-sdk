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
        return self.fetchBatched().ensure {

            // resume websocket events
            self.resumeMessages()

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

            // create endpoint over void
            let endpoint: Endpoint<Void> = API.Generic.getVatoms(withIDs: [vatomID])
            BLOCKv.client.request(endpoint).done { data in

                // convert
                guard
                    let object = try? JSONSerialization.jsonObject(with: data),
                    let json = object as? [String: Any],
                    let payload = json["payload"] as? [String: Any] else {
                    throw RegionError.failedParsingResponse
                }

                // parse out objects
                guard let items = self.parseDataObject(from: payload) else {
                    throw RegionError.failedParsingObject
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

    /// Page size parameter sent to the server.
    private let pageSize = 100
    /// Upper bound to prevent infinite recursion.
    private let maxReasonablePages = 50
    /// Number of batch iterations.
    private var iteration = 0
    /// Number of processed pages.
    private var proccessedPageCount = 0
    /// Cummulative object ids.
    fileprivate var cummulativeIds: [String] = []

}

extension InventoryRegion {

    func fetchBatched(maxConcurrent: Int = 4) -> Promise<[String]?> {

        let intialRange: CountableClosedRange<Int> = 1...maxConcurrent
        return fetchRange(intialRange)

    }

    private func fetchRange(_ range: CountableClosedRange<Int>) -> Promise<[String]?> {

        iteration += 1

        print("[Pager] fetching range \(range) in iteration \(iteration).")

        var promises: [Promise<[String]?>] = []

        // tracking flag
        var shouldRecurse = true

        for i in range {

            // build raw request
            let endpoint: Endpoint<Void> = API.Generic.getInventory(parentID: "*", page: i, limit: pageSize)

            // exectute request
            let promise = BLOCKv.client.requestJSON(endpoint).then(on: .global(qos: .userInitiated)) { json -> Promise<[String]?> in

                guard let json = json as? [String: Any],
                    let payload = json["payload"] as? [String: Any] else {
                        throw RegionError.failedParsingResponse
                }

                // parse out data objects
                guard let items = self.parseDataObject(from: payload) else {
                    return Promise.value([])
                }
                let newIds = items.map { $0.id }

                return Promise { (resolver: Resolver) in

                    DispatchQueue.main.async {

                        // append new ids
                        self.cummulativeIds.append(contentsOf: newIds)

                        // add data objects
                        self.add(objects: items)

                        if (items.count == 0) || (self.proccessedPageCount > self.maxReasonablePages) {
                            shouldRecurse = false
                        }
                        
                        // increment page count
                        self.proccessedPageCount += 1

                        return resolver.fulfill(newIds)

                    }
                }

            }

            promises.append(promise)

        }

        return when(resolved: promises).then { _ -> Promise<[String]?> in

            // check stopping condition
            if shouldRecurse {

                print("[Pager] recursing.")

                // create the next range (with equal width)
                let nextLower = range.upperBound.advanced(by: 1)
                let nextUpper = range.upperBound.advanced(by: range.upperBound)
                let nextRange: CountableClosedRange<Int> = nextLower...nextUpper

                return self.fetchRange(nextRange)

            } else {

                print("[Pager] stopping condition hit.")

                return Promise.value(self.cummulativeIds)

            }

        }

    }

}
