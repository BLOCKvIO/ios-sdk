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
///    > Importantly, for vatom additions, this pauses the message processing, fetches the vatom, and only resumes the
///    message processing.
///
/// # Synchronisation
///
/// Essentially there are 2 modes of synchronisation: full sync (V1) and parital sync (V2).
///
/// ## Full Sync (V1)
/// - The inventory endpoint is recursed to fetch all vatoms in the user's inventory. This includes all faces and actions.
/// - This method is simple since uses one synchronisation point, where it retireves the full state of the inventory at a particular
///   point in time (bar a few async annomalies on the backend).
/// - Drawbacks are that the entire payload must be fetched and processed.
///
/// ## Partial Sync (V2)
/// - This methods uses three synchronisation points.
/// 1. Inventory Hash - Informs the client of the state of all vatoms in the user's inventory. Equal hashes mean the inventory is in an
/// equivalent state.
///    - This hash however does NOT capture the state of the template's faces and actions. In other words, additions, deletions, or updates
///           will not affect the hash.
/// 2. Vatom Sync Nr. - This number respresents the state of a vatom and is incremented on every change. This allows the client to compate its
/// local sync numbers with that of the remote.
///    - Simlar to the hash, the sync nr. does NOT capture the state the template's faces and actions.
/// 3. Face & Action Since-Sync - To ensure the client has the latest faces and actions, the client can query the `face/changes` and
/// `action/changes` endpoints. These endpoints provide a changeset from the `since` date.
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

    /// Last hash value received from the server. `nil` if no value was received.
    var lastHash: String? {
        get { BVDefaults.shared.inventoryLastHash }
        set { BVDefaults.shared.inventoryLastHash = newValue }
    }
    
    var lastFaceActionFetch: TimeInterval? {
        get { BVDefaults.shared.inventoryLastFaceActionFetch }
        set { BVDefaults.shared.inventoryLastFaceActionFetch = newValue }
    }

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
    
    enum InventoryRegionError: Error {
        case invalidHash
    }

    /// Load current state from the server.
    ///
    /// 1. Call /hash API to get the current hash, if unchanged, stop.
    /// 2. Call /sync API to fetch all vatom sync numbers.
    /// 2.1 For all vatoms in the db not returned by /sync, remove.
    /// 2.2 For all vatoms present in /sync, but not in the db, add.
    /// 2.3 For all vatoms present in /sync and db, fetch the vatom and update.
    ///
    /// If at any point the sync APIs (v2) fail, fallback on fetching the entire inventory (v1).
    override func load() -> Promise<[String]?> {

        // pause websocket events
        self.pauseMessages()

        return self.fetchInventoryHash().then { newHash -> Promise<[String]?> in

            os_log("[InventoryRegion] Fetched hash: %@", log: .dataPool, type: .debug, newHash)

            // replace current hash
            let oldHash = self.lastHash
            self.lastHash = newHash

            if oldHash == nil {
                // this is a control flow error - don't worry
                throw InventoryRegionError.invalidHash
            }

            if oldHash == newHash {
                // process faces and actions
                return self.processFaceAndActionChanges().map { _ -> [String]? in return nil }
            } else {
                // fetch only mismatching sync vatoms
                return self.processSyncChanges().then {
                    return self.processFaceAndActionChanges().map { _ -> [String]? in return nil }
                }
            }

        }.recover({ error -> Promise<[String]?> in
            
            // this is expected on login, whereafter this should not occur
            os_log("[InventoryRegion] Falling back on full sync (v1): %@", log: .dataPool, type: .error,
                   error.localizedDescription)

            // fetch all pages recursively (v1)
            return self.fetchAllBatched()
        }).ensure {
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
    func processSyncChanges() -> Promise<Void> {

        // fetch sync numbers for *all* vatoms
        return self.fetchVatomSyncNumbers().then { newSyncModels -> Promise<Void> in
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
                        resolver.fulfill(Void())
                    }
                }
            }

            // fetch
            return self.fetchObjects(ids: Array(idsToFetch)).done { objects in

                // remove
                self.remove(ids: Array(idsToRemove))
                os_log("[InventoryRegion] Diff Sync: Did remove: %@", log: .dataPool, type: .debug,
                       idsToRemove.debugDescription)
                // add
                self.add(objects: objects)
                os_log("[InventoryRegion] Diff Sync: did add/update: %@", log: .dataPool, type: .debug,
                       objects.debugDescription)

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
                self.lastFaceActionFetch = Date().timeIntervalSince1970InMilliseconds
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

// MARK: - Face & Action Sync

extension InventoryRegion {

    enum ObjectType {
        case face
        case action
    }

    struct RemoteChangeDiff {
        var inserted: [DataObject] = []
        var deleted: [DataObject] = []
        var updated: [DataObject] = []

        /// Appends the other `RemoteChangeDiff` to this one.
        mutating func append(other: RemoteChangeDiff) {
            self.inserted.append(contentsOf: other.inserted)
            self.deleted.append(contentsOf: other.deleted)
            self.updated.append(contentsOf: other.updated)
        }
    }

    /// Processes face and actions sync changes.
    ///
    /// Cases where face and action changes are needed:
    /// - App comes into the foreground.
    /// - `load()` is called and the hash is the same (becuase we still don't know the state of face and actions)
    ///
    /// Returns a promise the resoves once all face and action changes have been processed for local templates.
    func processFaceAndActionChanges() -> Promise<RemoteChangeDiff> {
        
        guard let since = self.lastFaceActionFetch else {
            assertionFailure("Action and Face sync should only called after an inventory sync.")
            return Promise.value(RemoteChangeDiff())
        }
        
        let templateIds = Array(self.templateIds)
        let milliStart = Date().timeIntervalSince1970InMilliseconds
        
        // nothing to process
        if templateIds.isEmpty { return Promise.value(RemoteChangeDiff()) }
        
        var aggregateRemoteChangeDiff = RemoteChangeDiff()
        
        // server accepts a maximum of 100 template ids
        let chunks = templateIds.chunked(into: 100)
        
        func fetchChunk(index: Int) -> Promise<RemoteChangeDiff> {
            
            print("Fetching chunk index:", index)
            
            let templateIdsChunk = chunks[index]
            return self.fetchFaceAndActionChanges(templateIds: templateIdsChunk, since: since).then { remoteChangeDiff -> Promise<RemoteChangeDiff> in
                
                // build up
                aggregateRemoteChangeDiff.append(other: remoteChangeDiff)
                
                // update data-pool
                // (data-pool handles inserts and updates in one function)
                self.add(objects: remoteChangeDiff.inserted)
                self.add(objects: remoteChangeDiff.updated)
                let deleteIds = remoteChangeDiff.deleted.map { $0.id }
                self.remove(ids: deleteIds)
                
                // prepare for next iteration
                let nextIndex = index + 1
                if nextIndex < chunks.count {
                    return fetchChunk(index: nextIndex)
                } else {
                    // run through the diff and notify vatoms whose faces and actions have changed
                    self.processCummulativeDiff(diff: aggregateRemoteChangeDiff)
                    self.lastFaceActionFetch = milliStart
                    return Promise.value(aggregateRemoteChangeDiff)
                }
                
            }
            
        }
        
        return fetchChunk(index: 0)

    }

    /// Fetches face and action changes and combines them into a single `RemoteChangeDiff`.
    func fetchFaceAndActionChanges(templateIds: [String], since: TimeInterval) -> Promise<RemoteChangeDiff> {

        var changeDiff = RemoteChangeDiff()

        let facePromise = self.fetchChanges(for: .face, templateIds: templateIds, since: since).done { faceDiff in
            changeDiff.append(other: faceDiff)
        }

        let actionPromise = self.fetchChanges(for: .action, templateIds: templateIds, since: since).done { actionDiff in
            changeDiff.append(other: actionDiff)
        }

        return when(fulfilled: facePromise, actionPromise).map { (_, _) -> RemoteChangeDiff in
            return changeDiff
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
                    let type = mod[key] as? [String: Any] else {
                        throw RegionError.failedParsingResponse
                }
                
                // create data object
                let obj = DataObject()
                obj.type = key
                obj.id = type["id"] as? String ?? ""
                obj.data = type

                switch operation {
                case "create":
                    remoteChangeDiff.inserted.append(obj)
                case "delete":
                    remoteChangeDiff.deleted.append(obj)
                case "update":
                    remoteChangeDiff.updated.append(obj)
                default:
                    fatalError()
                }
            }

        }

        return remoteChangeDiff

    }
    
    func processCummulativeDiff(diff: RemoteChangeDiff) {
        
        /*
         Essentially, the new 'process face and actions' stuff, where faces and actions are added, removed, updated
         independently means instances the vatom update noitfication wont include the actions and faces changes.
         
         This function go over all vatom object and then broadcast an update notification if either an action or face
         has changed.
         It's then up to the vatom view to re-pull the vatom from data pool (at which point the vatom will have the
         latest package).
         */
        
        var uniqueTemplates: Set<String> = []
        
        for object in diff.inserted {
            uniqueTemplates.insert(object.templateId)
        }
        for object in diff.updated {
            uniqueTemplates.insert(object.templateId)
        }
        for object in diff.deleted {
            uniqueTemplates.insert(object.templateId)
        }
        
        // loop over all vatom objects and see if their template's faces or actions were modified
        for object in self.objects where object.value.type == "vatom" {
            
            if uniqueTemplates.contains(object.value.templateId) {
                // broadcast that the object has been updated (in this case with a change in faces and/or actions)
                self.did(update: object.value, to: object.value, withFields: object.value.data!)
            }
            
        }
        
    }

}

extension Date {
    
    var timeIntervalSince1970InMilliseconds: TimeInterval {
        Double(Int(self.timeIntervalSince1970 * 1000))
    }
    
}

extension DataObject {
    
    /// Extracts the id of the template associated with this object.
    var templateId: String {
        
        switch type {
        case "vatom":
            return (self.data?["vAtom::vAtomType"] as? [String: Any])?["template"] as? String ?? ""
        case "face":
            return (self.data?["template"] as? String) ?? ""
        case "action":
            guard
                let name = self.data?["name"] as? String,
                let templateID = try? ActionModel.splitCompoundName(name).templateID
                else { return "" }
            return templateID
        default:
            fatalError("Unsupported object type.")
        }
        
    }
    
}
