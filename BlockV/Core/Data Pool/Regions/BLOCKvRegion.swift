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
import MoreCodable

/// Abstract subclass of `Region`. This intermediate class handles updates from the BLOCKv Web socket. Regions should
/// subclass to automatically handle Web socket updates.
///
/// Roles:
/// - Handles Web socket events (including queuing, pausing, and processing).
/// - Messages are transformed into DataObjectUpdateRecord (Sparse Object) and use to update the region.
/// - Data transformations (map) to VatomModel
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

        // Monitor for timed updates
        DataObjectAnimator.shared.add(region: self)

    }

    deinit {

        //FIXME: As I understand it, the signals will not need to be unsubscribed from.

        // Stop listening for animation updates
        DataObjectAnimator.shared.remove(region: self)

    }

    /// Queue of pending Web socket messages
    private var queuedMessages: [[String: Any]] = []

    /// True if Web socket processing is paused
    private var socketPaused = false
    private var socketProcessing = false

    /// Called when this region is going to be shut down
    override func close() {
        super.close()

        //FIXME: Double check that signals do not need to be unsubscribed from.

        // Remove listeners
        DataObjectAnimator.shared.remove(region: self)

    }

    /// Called to pause processing of web socket messages
    func pauseMessages() {
        self.socketPaused = true
    }

    /// Called to resume processing of web socket messages
    func resumeMessages() {

        // Unpause
        self.socketPaused = false

        // Process next message if needed
        if !self.socketProcessing {
            self.processNextMessage()
        }

    }

    /// Called when the web socket reconnects
    @objc func onWebSocketConnect() {

        // Mark as unstable
        self.synchronized = false

        // Re-sync the entire thing. Don't worry about synchronize() getting called while it's running already,
        // it handles that case.
        self.synchronize()

    }

    /// Called when there's a new event message via the Web socket.
    @objc func onWebSocketMessage(_ descriptor: [String: Any]) {

        // Add to queue
        self.queuedMessages.append(descriptor)

        // Process it if necessary
        if !self.socketPaused && !self.socketProcessing {
            self.processNextMessage()
        }

    }

    /// Called to process the next WebSocket message.
    func processNextMessage() {

        // Stop if socket is paused
        if socketPaused {
            return
        }

        // Stop if already processing
        if socketProcessing { return }
        socketProcessing = true

        // Get next msg to process
        if queuedMessages.count == 0 {

            // No more messages!
            self.socketProcessing = false
            return

        }

        // Process message
        let msg = queuedMessages.removeFirst()
        self.processMessage(msg)

        // Done, process next message
        self.socketProcessing = false
        self.processNextMessage()

    }

    /// Processes a raw Web socket message.
    func processMessage(_ msg: [String: Any]) {

        // Get info
        guard let msgType = msg["msg_type"] as? String else { return }
        guard let payload = msg["payload"] as? [String: Any] else { return }
        guard let newData = payload["new_object"] as? [String: Any] else { return }
        guard let vatomID = payload["id"] as? String else { return }
        if msgType != "state_update" {
            return
        }

        // Update existing objects
        let changes = DataObjectUpdateRecord(id: vatomID, changes: newData)
        self.update(objects: [changes])

    }

    /// Map data objects to Vatom objects.
    override func map(_ object: DataObject) -> Any? {

        // Only handle vatoms
        guard object.type == "vatom" else {
            return nil
        }

        // Stop if no data available
        guard var objectData = object.data else {
            return nil
        }

        let decoder = DictionaryDecoder()

        // Get vatom info
        guard let template = object.data![keyPath: "vAtom::vAtomType.template"] as? String else { return nil }

        // Fetch all faces linked to this vatom
        let faces = objects.values.filter { $0.type == "face" && $0.data?["template"] as? String == template }
        objectData["faces"] = faces

        // Fetch all actions linked to this vatom
        let actionNamePrefix = template + "::Action::"
        let actions = objects.values.filter { $0.type == "action" && ($0.data?["name"] as? String)?
            .starts(with: actionNamePrefix) == true }
        objectData["actions"] = actions

        // create and return a new instance
        return try? decoder.decode(VatomModel.self, from: objectData)

    }

    /// Called when an object is about to be added.
    override func will(add object: DataObject) {

        // Notify parent as well
        guard let parentID = (object.data?["vAtom::vAtomType"] as? [String: Any])?["parent_id"] as? String else {
            return
        }
        DispatchQueue.main.async {
            self.emit(.objectUpdated, userInfo: ["id": parentID])
        }

    }

    /// Called when an object is about to be updated.
    override func will(update object: DataObject, withFields: [String: Any]) {

        // Notify parent as well
        guard let oldParentID = (object.data?["vAtom::vAtomType"] as? [String: Any])?["parent_id"] as? String else {
            return
        }
        guard let newParentID = (withFields["vAtom::vAtomType"] as? [String: Any])?["parent_id"] as? String else {
            return
        }
        DispatchQueue.main.async {
            self.emit(.objectUpdated, userInfo: ["id": oldParentID])
            self.emit(.objectUpdated, userInfo: ["id": newParentID])
        }

    }

    /// Called when an object is about to be updated.
    override func will(update: DataObject, keyPath: String, oldValue: Any?, newValue: Any?) {

        // Check if parent ID is changing
        if keyPath != "vAtom::vAtomType.parent_id" {
            return
        }

        // Notify parent as well
        guard let oldParentID = oldValue as? String else { return }
        guard let newParentID = newValue as? String else { return }
        DispatchQueue.main.async {
            self.emit(.objectUpdated, userInfo: ["id": oldParentID])
            self.emit(.objectUpdated, userInfo: ["id": newParentID])
        }

    }

    /// Called when an object is about to be removed.
    override func will(remove object: DataObject) {

        // Notify parent as well
        guard let parentID = (object.data?["vAtom::vAtomType"] as? [String: Any])?["parent_id"] as? String else { return }
        DispatchQueue.main.async {
            self.emit(.objectUpdated, userInfo: ["id": parentID])
        }

    }

}
