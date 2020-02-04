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
            os_log("[InventoryRegion] Accessed prior to valid user session.", log: .dataPool, type: .error)
            throw NSError("You cannot query the inventory region without being logged in.")
        }

    }

    var lastHash: String?

    // called in response to a premtive action
    override func onPreemptiveChange(_ object: DataObject) {
        super.onPreemptiveChange(object)
        // nil out hash
        self.lastHash = nil
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
    ///
    /// 1. Call /hash API to get the current hash, if unchanged, stop.
    /// 2. Call /sync API to fetch all vatom sync numbers.
    /// 2.1 For all vatoms in the db not returned by /sync, remove.
    /// 2.2 For all vatoms present in /sync, but not in the db, add.
    /// 2.3 For all vatoms present in /sync and db, fetch the vatom and update.
    ///
    /// If at any point the sync APIs fail, fallback on fetching the entire inventory.
    override func load() -> Promise<[String]?> {

        // pause websocket events
        self.pauseMessages()

        return self.fetchInventoryHash().then { newHash -> Promise<[String]?> in

            os_log("[InventoryRegion] Fetched hash: %@", log: .dataPool, type: .debug, newHash)

            // replace current hash
            let oldHash = self.lastHash
            self.lastHash = newHash

            if oldHash == newHash {
                // nothing has changes
                self.resumeMessages()
                // return nil(no-op)
                return Promise.value(nil)
            }

            // fetch changes recursively
            return self.fetchChanges().ensure {
                // resume websocket events
                self.resumeMessages()
            }

        }.recover({ error -> Promise<[String]?> in

            os_log("[InventoryRegion] Unable to fetch inventory hash: %@", log: .dataPool, type: .error,
                   error.localizedDescription)

            // fetch all pages recursively
            return self.fetchAllBatched().ensure {
                // resume websocket events
                self.resumeMessages()
            }
        })

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

        // nil out the hash if something has changed
        if msgType == "inventory" || msgType == "state_update" {
            self.lastHash = nil
        }

        if msgType != "inventory" { return }

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
                os_log("[InventoryRegion] Unable to fetch vatom: %@", log: .dataPool, type: .error, vatomID)
            }.finally {
                // resume WebSocket processing
                self.resumeMessages()
            }

        } else {

            // logic error, old owner and new owner cannot be the same
            let errorMessage = """
            [InventoryRegion] Logic error in WebSocket message, old_owner and new_owner shouldn't be the same:
            \(vatomID)
            """
            printBV(error: errorMessage)

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

    /// Fetches only changed items (based on sync state).
    func fetchChanges() -> Promise<[String]?> {
        
        self.processFaceAndActionChanges()

        // fetch sync numbers for *all* vatoms
        return self.fetchVatomSyncNumbers().then { newSyncModels -> Promise<[String]?> in
            // printBV(info: "[InventoryRegion] Sync models: \n\(syncModels)")

            let currentIds = Set(self.vatomObjects.keys)
            let syncIds = Set(newSyncModels.map { $0.id })

            let idsToRemove = currentIds.subtracting(syncIds)
            os_log("[InventoryRegion] Diff Sync: Will remove: %@", log: .dataPool, type: .debug, idsToRemove.debugDescription)

            let idsToAdd = syncIds.subtracting(currentIds)
            os_log("[InventoryRegion] Diff Sync: Will add: %@", log: .dataPool, type: .debug, idsToAdd.debugDescription)

            var idsToFetch: Set<String> = idsToAdd

            // sync of zero mean no change, ignore
            let filteredNewSyncModels = newSyncModels.filter { $0.sync != 0 }
            // find the vatoms whose sync numbers have changed
            let idsToUpdate = filteredNewSyncModels.filter { newSyncModel -> Bool in
                return self.vatomSyncObjects.contains(where: {
                    $0.id == newSyncModel.id && $0.sync != newSyncModel.sync
                })
            }

            // fetch all added + updated ids
            idsToFetch.formUnion(idsToUpdate.map { $0.id })
            // printBV(info: "[InventoryRegion] Sync will fetch:")
            // idsToFetch.forEach { print(" - " + $0) }

            if idsToFetch.isEmpty {
                // nothing to fetch, so just remove
                return Promise { (resolver: Resolver) in
                    DispatchQueue.main.async {
                        // remove
                        self.remove(ids: Array(idsToRemove))
                        os_log("[InventoryRegion] Diff Sync: Did remove: %@", log: .dataPool, type: .debug,
                               idsToRemove.debugDescription)
                        resolver.fulfill(nil)
                    }
                }
            }

            // fetch
            return self.fetchObjects(ids: Array(idsToFetch)).then { objects -> Promise<[String]?> in

                // remove
                self.remove(ids: Array(idsToRemove))
                os_log("[InventoryRegion] Diff Sync: Did remove: %@", log: .dataPool, type: .debug,
                       idsToRemove.debugDescription)
                // add
                self.add(objects: objects)
                os_log("[InventoryRegion] Diff Sync: did add/update: %@", log: .dataPool, type: .debug,
                       objects.debugDescription)

                return Promise.value(nil)

            }

        }

    }

    /// Fetches all items (irrespective of sync state).
    func fetchAllBatched(maxConcurrent: Int = 4) -> Promise<[String]?> {

        let intialRange: CountableClosedRange<Int> = 1...maxConcurrent
        return fetchRange(intialRange)

    }

    private func fetchRange(_ range: CountableClosedRange<Int>) -> Promise<[String]?> {

        iteration += 1
        os_log("[InventoryRegion] Full Sync: Fetcing Range: %@, Iteration: %d", log: .dataPool, type: .debug,
               range.debugDescription, iteration)

        var promises: [Promise<[String]?>] = []

        // tracking flag
        var shouldRecurse = true

        for page in range {

            // build raw request
            let endpoint: Endpoint<Void> = API.Generic.getInventory(parentID: "*", page: page, limit: pageSize)

            // exectute request
            let promise = BLOCKv.client.requestJSON(endpoint)
                .then(on: .global(qos: .userInitiated)) { json -> Promise<[String]?> in

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

                // create the next range (with equal width)
                let nextLower = range.upperBound.advanced(by: 1)
                let nextUpper = range.upperBound.advanced(by: range.upperBound)
                let nextRange: CountableClosedRange<Int> = nextLower...nextUpper

                return self.fetchRange(nextRange)

            } else {
                os_log("[InventoryRegion] Full Sync: Stopped on page %d", log: .dataPool, type: .debug,
                       self.proccessedPageCount)
                return Promise.value(self.cummulativeIds)
            }

        }

    }

}

extension InventoryRegion {

    /// Fetches the remote inventory's hash value.
    func fetchInventoryHash() -> Promise<String> {

        let endpoint = API.Vatom.getInventoryHash()
        return BLOCKv.client.request(endpoint).map { result -> String in
            return result.payload.hash
        }

    }

    /// Fetches all remote inventory vatom sync numbers.
    ///
    /// This function recurses through server pages.
    func fetchVatomSyncNumbers() -> Promise<[VatomSyncModel]> {

        var cummulativeSyncModels: [VatomSyncModel] = []

        func fetchInventoryVatomSyncNumbers(limit: Int = 1000, token: String = "") -> Promise<[VatomSyncModel]> {

            let endpoint = API.Vatom.getInventoryVatomSyncNumbers(limit: limit, token: token)
            return BLOCKv.client.request(endpoint).then { result -> Promise<[VatomSyncModel]> in

                // printBV(info: "[InventoryRegion] Sync result: token: \(token)")
                // result.payload.vatoms.forEach { print(" - " + $0.id + " sync: " + String($0.sync)) }

                // accumulate
                cummulativeSyncModels += result.payload.vatoms

                // check stopping codintion (base case)
                if result.payload.nextToken == "" || result.payload.vatoms.isEmpty {
                    return Promise.value(cummulativeSyncModels)
                }
                // prepare for next iteration
                let nextToken = result.payload.nextToken
                return fetchInventoryVatomSyncNumbers(limit: limit, token: nextToken)
            }

        }

        return fetchInventoryVatomSyncNumbers()

    }

    /// Fetch data objects for the specified vatom ids.
    ///
    /// Splits large (> 100) into multipe network requests.
    func fetchObjects(ids: [String]) -> Promise<[DataObject]> {

        //TODO: Could benefit from parallelelization

        if ids.isEmpty { return Promise.value([]) }
        let chunks = ids.chunked(into: 100)

        var cummulativeObjects: [DataObject] = []

        func fetchChunk(index: Int) -> Promise<[DataObject]> {

            let endpoint: Endpoint<Void> = API.Generic.getVatoms(withIDs: chunks[index])
            return BLOCKv.client.requestJSON(endpoint)
                .then(on: .global(qos: .userInitiated)) { json -> Promise<[DataObject]> in
                    // parse
                    guard let json = json as? [String: Any],
                        let payload = json["payload"] as? [String: Any] else {
                            throw RegionError.failedParsingResponse
                    }
                    // parse out data objects
                    guard let items = self.parseDataObject(from: payload) else {
                        throw RegionError.failedParsingResponse
                    }

                    // accumulate
                    cummulativeObjects += items

                    // prepare for next iteration
                    let nextIndex = index + 1
                    if nextIndex < chunks.count {
                        return fetchChunk(index: nextIndex)
                    } else {
                        return Promise.value(cummulativeObjects)
                    }

            }
        }

        return fetchChunk(index: 0)

    }
    
}

extension InventoryRegion {
    
    //TODO: This code must get called with synchronizartion in mind.
    // However if synchronization is happending, then this is not needed.
    //
    // Cases where face and action changes are needed:
    // - App comes into the foreground.
    // - A full synchronization is done.
    func processFaceAndActionChanges() -> Promise<Void> {
        
        return self.fetchFaceAndActionChanges().done { remoteChangeDiff in
            
            print("Remote changes", remoteChangeDiff)
            //TODO: Update data pool.
            
        

            
        }
        
    }
    
    /*
     This must be called *after* data pool sync. This is because all the templates must be downloaded..
     Actually, do they need to be, if there are new templates, then the whole vatom package would need to be downloaded..
     */

    /// Fetches and processes face and action changes.
    func fetchFaceAndActionChanges() -> Promise<RemoteChangeDiff> {
        
        //FIXME: Need to store and retrieve since timestamp
        
        // time
        let nowNano: TimeInterval = Double(Int(Date().timeIntervalSince1970) * 1000_000)
        let since: TimeInterval = 1580376600000 // nowNano - (2678400000 * 1000)
        print("since", since)
        
        let templateIds = Array(self.templateIds)
        
        var changeDiff = RemoteChangeDiff()
        
        let facePromise = self.fetchChanges(for: .face, templateIds: templateIds, since: since).done { faceDiff in
            changeDiff.merge(other: faceDiff)
        }
        
        let actionPromise = self.fetchChanges(for: .action, templateIds: templateIds, since: since).done { actionDiff in
            changeDiff.merge(other: actionDiff)
        }
        
        return when(fulfilled: facePromise, actionPromise).map { (_, _) -> RemoteChangeDiff in
            return changeDiff
        }
        
    }
     
     enum ObjectType {
         case face
         case action
     }
    
    struct RemoteChangeDiff {
        var inserted: [DataObject] = []
        var deleted: [String] = []
        var updated: [DataObject] = []
        
        mutating func merge(other: RemoteChangeDiff) {
            self.inserted.append(contentsOf: other.inserted)
            self.deleted.append(contentsOf: other.deleted)
            self.updated.append(contentsOf: other.updated)
        }
    }
    
    /// Fetches the remote change set for the specified object type (e.g. face, action).
    ///
    /// - Parameters:
    ///   - objectType: The object type to fetch (e.g. face or action).
    ///   - templateIds: List of template ids whose remote changes should be fetched.
    ///   - since: Timestamp after which the changes should be computed (measures as unix epoch in milliseconds).
    func fetchChanges(for objectType: ObjectType, templateIds: [String], since: TimeInterval) -> Promise<RemoteChangeDiff> {

        let endpoint: Endpoint<Void>
        switch objectType {
        case .face:
            endpoint = API.Generic.getFaceChanges(templateIds: templateIds, since: since)
        case .action:
            endpoint = API.Generic.getActionChanges(templateIds: templateIds, since: since)
        }
        
        return BLOCKv.client.requestJSONParsed(endpoint)
            .then(on: .global(qos: .userInitiated)) { (_, payload) -> Promise<RemoteChangeDiff> in
                // parse out changes
                let remoteChangeDiff = try self.parseRemoteChanges(payload: payload, objectType: objectType)
                return Promise.value(remoteChangeDiff)
        }

    }

    /// Parses out a remote change set given the payload and object type.
    ///
    /// This function is able to parse both face and action change sets by passing in an `ObjectType`.
    private func parseRemoteChanges(payload: [String: Any], objectType: ObjectType) throws -> RemoteChangeDiff {
        
        let key: String
        let payloadKey: String
        
        switch objectType {
        case .face:
            key = "face"
            payloadKey = "faces_changes"
        case .action:
            key = "action"
            payloadKey = "actions_changes"
        }
        
        // parse out objects
        guard let changes = payload[payloadKey] as? [String: [[String: Any]]] else {
            throw RegionError.failedParsingResponse
        }
        
        // create data objects to be added
        var remoteChangeDiff = RemoteChangeDiff()
        
        // loop through array of template id to modifications map
        for templateMap in changes {
            
            let modifications = templateMap.value
            
            // loop over each modification (for the template)
            for mod in modifications {
                
                guard let operation = mod["operation"] as? String,
                    let face = mod[key] as? [String: Any] else {
                        throw RegionError.failedParsingResponse
                }

                switch operation {
                case "create":
                    // create data object
                    let obj = DataObject()
                    obj.type = key
                    obj.id = face["id"] as? String ?? ""
                    obj.data = face
                    // flag for insertion
                    remoteChangeDiff.inserted.append(obj)

                case "delete":
                    // flag for deletion
                    if let id = face["id"] as? String {
                        remoteChangeDiff.deleted.append(id)
                    }

                default:
                    fatalError()
                }
            }
            
        }
        
        return remoteChangeDiff
        
    }

}
