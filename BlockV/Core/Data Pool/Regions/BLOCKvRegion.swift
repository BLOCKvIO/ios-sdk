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

/// Abstract subclass of `Region`. This intermediate class handles updates from the BLOCKv Web socket. Regions should
/// subclass to automatically handle Web socket updates.
///
/// The BLOCKv subclass is hardcoded to treat the 'objects' as vatoms. That is, the freeform object must be a vatom.
/// This is a product of the design, but it could be generalised in the future if say faces were to become a monitored
/// region.
///
/// Roles:
/// - Handles some Web socket events (including queuing, pausing, and processing).
/// - Only 'state_update' events are intercepted.
///   > State-update messages are transformed into DataObjectUpdateRecord (Sparse Object) and use to update the region.
/// - Data transformations (map) to VatomModel
/// - Notifications
///   > Add, update, remove notification are broadcast for the changed vatom. An update is always emitted for the parent
///   of the changed vatom. This is useful since the parent can then update its state, e.g. on child removal.
/// - Parsing unpackaged vatom payload into data-objects.
class BLOCKvRegion: Region {

    /// Constructor
    required init(descriptor: Any) throws {
        try super.init(descriptor: descriptor)

        // subscribe to socket connections
        BLOCKv.socket.onConnected.subscribe(with: self) { _ in
            self.onWebSocketConnect()
        }

        // subscribe to raw socket messages
        BLOCKv.socket.onMessageReceivedRaw.subscribe(with: self) { descriptor in
            self.onWebSocketMessage(descriptor)
        }

        // monitor for timed updates
        DataObjectAnimator.shared.add(region: self)

    }

    deinit {

        // stop listening for animation updates
        DataObjectAnimator.shared.remove(region: self)

    }

    /// Queue of pending messages.
    private var queuedMessages: [[String: Any]] = []
    /// Boolean value that is `true` if message processing is paused.
    private var socketPaused = false
    /// Boolean valie that is `true` if a message is currently being processed.
    private var socketProcessing = false

    /// Called when this region is going to be shut down.
    override func close() {
        super.close()

        // remove listeners
        DataObjectAnimator.shared.remove(region: self)

    }

    /// Called to pause processing of socket messages.
    func pauseMessages() {
        self.socketPaused = true
    }

    /// Called to resume processing of socket messages.
    func resumeMessages() {

        // unpause
        self.socketPaused = false

        // process next message if needed
        if !self.socketProcessing {
            self.processNextMessage()
        }

    }

    /// Called when the Web socket re-connects.
    @objc func onWebSocketConnect() {

        // mark as unstable
        self.synchronized = false

        // re-sync the entire thing. Don't worry about synchronize() getting called while it's running already,
        // it handles that case.
        self.synchronize()

    }

    /// Called when there's a new event message via the Web socket.
    @objc func onWebSocketMessage(_ descriptor: [String: Any]) {

        // add to queue
        self.queuedMessages.append(descriptor)

        // process it if necessary
        if !self.socketPaused && !self.socketProcessing {
            self.processNextMessage()
        }

    }

    /// Called to process the next WebSocket message.
    func processNextMessage() {

        // stop if socket is paused
        if socketPaused {
            return
        }

        // stop if already processing
        if socketProcessing { return }
        socketProcessing = true

        // get next msg to process
        if queuedMessages.count == 0 {

            // no more messages
            self.socketProcessing = false
            return

        }

        // process message
        let msg = queuedMessages.removeFirst()
        self.processMessage(msg)

        // done, process next message
        self.socketProcessing = false
        self.processNextMessage()

    }

    /// Processes a raw Web socket message.
    ///
    /// Only 'state_update' events intercepted and used to perform parital updates on the region's objects.
    /// Message processing is not paused for 'state_update' events.
    func processMessage(_ msg: [String: Any]) {

        // get info
        guard let msgType = msg["msg_type"] as? String else { return }
        guard let payload = msg["payload"] as? [String: Any] else { return }
        guard let newData = payload["new_object"] as? [String: Any] else { return }
        guard let vatomID = payload["id"] as? String else { return }
        if msgType != "state_update" {
            return
        }

        // update existing objects
        let changes = DataObjectUpdateRecord(id: vatomID, changes: newData)
        self.update(objects: [changes])

    }

    // MARK: - Transformations

    /// Map data objects to Vatom objects.
    ///
    /// This is the primary transformation function which converts freeform data pool objects into concrete types.
    override func map(_ object: DataObject) -> Any? {

        //FIXME: This method is synchronous which may affect performance.

        /*
         How to transfrom data objects into types?
         
         Data > Decoder > Type (decode from external representation)
         Type > Encoder > Data (encode for extrernal representation)
         
         Facts:
         - Data pool store heterogeneous object of type [String: Any] - it is type independent.
         - `map(:DataObject)` needs to transformt this into a concrete type.
         - The codable machinary is good for data <> native type transformations.
         
         
         Options:
         1. Convert [String: Any] into Data, then Data into Type (very inefficient).
         2. Write an init(descriptor: [String: Any])` - this allows VatomModel to be initialized with a dictionary.
         > This sucks because a) it's a lot of work, b) does not leverage the CodingKeys of Codable conformance.
         3. Write a Decoder with transforms [String: Any] into Type AND leverages the CodingKeys
         */

        // only handle vatoms
        guard object.type == "vatom" else {
            return nil
        }

        // stop if no data available
        guard var objectData = object.data else {
            return nil
        }

        // get vatom info
        guard let template = object.data![keyPath: "vAtom::vAtomType.template"] as? String else { return nil }

        // fetch all faces linked to this vatom
        let faces = objects.values.filter { $0.type == "face" && $0.data?["template"] as? String == template }
        objectData["faces"] = faces.map { $0.data }

        // fetch all actions linked to this vatom
        let actionNamePrefix = template + "::Action::"
        let actions = objects.values.filter { $0.type == "action" && ($0.data?["name"] as? String)?
            .starts(with: actionNamePrefix) == true }
        objectData["actions"] = actions.map { $0.data }

        // create vatoms, face, anf actions using member-wise initilializer
        do {
            let faces = faces.compactMap { $0.data }.compactMap { try? FaceModel(from: $0) }
            let actions = actions.compactMap { $0.data }.compactMap { try? ActionModel(from: $0) }
            var vatom = try VatomModel(from: objectData)
            vatom.faceModels = faces
            vatom.actionModels = actions
            return vatom
        } catch {
            os_log("[%@] Package intialization failure: %@", log: .dataPool, type: .error, typeName(self),
                   error.localizedDescription)
            return nil
        }

    }

    /// Parses the unpackaged vatom payload from the server and returns an array of `DataObject`.
    ///
    /// Returns `nil` if the payload cannot be parsed.
    func parseDataObject(from payload: [String: Any]) -> [DataObject]? {

        // create list of items
        var items: [DataObject] = []

        // ensure
        guard
            let vatoms = payload["vatoms"] as? [[String: Any]] ?? payload["results"] as? [[String: Any]],
            let faces = payload["faces"] as? [[String: Any]],
            let actions = payload["actions"] as? [[String: Any]]
            else { return nil }

        // add faces to the list
        for face in faces {

            // add data object
            let obj = DataObject()
            obj.type = "face"
            obj.id = face["id"] as? String ?? ""
            obj.data = face
            items.append(obj)

        }

        // add actions to the list
        for action in actions {

            // add data object
            let obj = DataObject()
            obj.type = "action"
            obj.id = action["name"] as? String ?? ""
            obj.data = action
            items.append(obj)

        }

        // add vatoms to the list
        for vatom in vatoms {

            // add data object
            let obj = DataObject()
            obj.type = "vatom"
            obj.id = vatom["id"] as? String ?? ""
            obj.data = vatom
            items.append(obj)

        }

        return items

    }

    // called in response to a premtive action
    override func onPreemptiveChange(_ object: DataObject) {
        super.onPreemptiveChange(object)

        if object.type == "vatom" {
            // indicate a re-sync with remote is required
            object.data![keyPath: KeyPath("vAtom::vAtomType.sync")] = -1
        }
    }

    // MARK: - Notifications

    // - Add

    /// Called when an object is about to be added.
    override func will(add object: DataObject) {

        // notify parent
        guard let vatomType = (object.data?["vAtom::vAtomType"] as? [String: Any]),
            let parentID = vatomType["parent_id"] as? String else {
            return
        }
        DispatchQueue.main.async {
            // broadcast update the vatom's parent
            self.emit(.willUpdateObject, userInfo: ["id": parentID])
            // broadbast the add
            self.emit(.willAddObject, userInfo: ["id": object.id])
        }

    }

    override func did(add object: DataObject) {

        // notify parent
        guard let vatomType = (object.data?["vAtom::vAtomType"] as? [String: Any]),
            let parentID = vatomType["parent_id"] as? String else {
                return
        }
        DispatchQueue.main.async {
            // broadcast update the vatom's parent
            self.emit(.didUpdateObject, userInfo: ["id": parentID])
            // broadbast the add
            self.emit(.didAddObject, userInfo: ["id": object.id])
        }
    }

    // - Update

    /// Called when an object is about to be updated.
    override func will(update object: DataObject, withFields: [String: Any]) {

        if let oldParentID = (object.data?["vAtom::vAtomType"] as? [String: Any])?["parent_id"] as? String,
            let newParentID = (withFields["vAtom::vAtomType"] as? [String: Any])?["parent_id"] as? String {
            // notify parents
            DispatchQueue.main.async {
                self.emit(.willUpdateObject, userInfo: ["id": oldParentID])
                if oldParentID != newParentID {
                    self.emit(.willUpdateObject, userInfo: ["id": newParentID])
                }
            }
        }
        // notify object
        DispatchQueue.main.async {
            self.emit(.willUpdateObject, userInfo: ["id": object.id])
        }

    }

    /// Called when an object is about to be updated.
    override func did(update from: DataObject, to: DataObject, withFields: [String: Any]) {

        // notify parents
        if let oldParentID = (from.data?["vAtom::vAtomType"] as? [String: Any])?["parent_id"] as? String,
            let newParentID = (to.data?["vAtom::vAtomType"] as? [String: Any])?["parent_id"] as? String {
            DispatchQueue.main.async {
                self.emit(.didUpdateObject, userInfo: ["id": oldParentID])
                if oldParentID != newParentID {
                    self.emit(.didUpdateObject, userInfo: ["id": newParentID])
                }
            }
        }
        // notify object
        DispatchQueue.main.async {
            self.emit(.didUpdateObject, userInfo: ["id": to.id])
        }
    }

    /// Called when an object is about to be updated.
    override func will(update: DataObject, keyPath: String, oldValue: Any?, newValue: Any?) {

        // check if parent ID is changing
        if keyPath == "vAtom::vAtomType.parent_id" {
            // notify parents
            guard let oldParentID = oldValue as? String else { return }
            guard let newParentID = newValue as? String else { return }
            DispatchQueue.main.async {
                self.emit(.willUpdateObject, userInfo: ["id": oldParentID])
                if oldParentID != newParentID {
                    self.emit(.willUpdateObject, userInfo: ["id": newParentID])
                }
            }
        }

        self.emit(.willUpdateObject, userInfo: ["id": update.id])

    }

    /// Called when an object is about to be updated.
    override func did(update: DataObject, keyPath: String, oldValue: Any?, newValue: Any?) {

        // check if parent ID is changing
        if keyPath == "vAtom::vAtomType.parent_id" {
            // notify parents
            guard let oldParentID = oldValue as? String else { return }
            guard let newParentID = newValue as? String else { return }
            DispatchQueue.main.async {
                self.emit(.didUpdateObject, userInfo: ["id": oldParentID])
                if oldParentID != newParentID {
                    self.emit(.didUpdateObject, userInfo: ["id": newParentID])
                }
            }
        }

        self.emit(.didUpdateObject, userInfo: ["id": update.id])

    }

    // - Remove

    /// Called when an object is about to be removed.
    override func will(remove object: DataObject) {

        // notify parent as well
        guard let vatomType = (object.data?["vAtom::vAtomType"] as? [String: Any]),
            let parentID = vatomType["parent_id"] as? String else {
                return
        }
        DispatchQueue.main.async {
            if parentID != "." {
                self.emit(.willUpdateObject, userInfo: ["id": parentID])
            }
            self.emit(.willRemoveObject, userInfo: ["id": object.id])
        }

    }

    /// Called when an object has been removed.
    override func did(remove object: DataObject) {

        // notify parent as well
        guard let vatomType = (object.data?["vAtom::vAtomType"] as? [String: Any]),
            let parentID = vatomType["parent_id"] as? String else {
                return
        }
        DispatchQueue.main.async {
            if parentID != "." {
                self.emit(.didUpdateObject, userInfo: ["id": parentID])
            }
            self.emit(.didRemoveObject, userInfo: ["id": object.id])
        }

    }

}

/// Convenience computed properties.
extension BLOCKvRegion {

    /// Returns a dictionary of objects where type is 'vatom'.
    var vatomObjects: [String: DataObject] {
        return self.objects.filter { $0.value.type == "vatom" }
    }
    /// Returns a dictionary of objects where type is 'face'.
    var faceObject: [String: DataObject] {
        return self.objects.filter { $0.value.type == "face"}
    }
    /// Returns a dictionary of objects where type is 'action'.
    var actionObject: [String: DataObject] {
        return self.objects.filter { $0.value.type == "action"}
    }

    var vatomSyncObjects: [VatomSyncModel] {
        return self.vatomObjects.map { VatomSyncModel(id: $0.value.id, sync: ($0.value.data?["sync"] as? UInt) ?? 0) }
    }

}

extension BLOCKvRegion {
    
    /// Returns the set of template ids associated with objects in this region.
    var templateIds: Set<String> {
        
        // unique set of template ids
        var templateIds: Set<String> = []
        
        for object in self.objects {
            if object.value.type == "vatom" {
                if let tempId = (object.value.data?["vAtom::vAtomType"] as? [String: Any])?["template"] as? String {
                    templateIds.insert(tempId)
                }
            }
        }
        
        return templateIds
        
    }
    
}
