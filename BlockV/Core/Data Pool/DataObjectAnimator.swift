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

/// Singleton. Responsible for receiving, storing, and exeucting changes to objects over time.
internal class DataObjectAnimator {

    /// Singleton
    static let shared = DataObjectAnimator()

    /// List of regions that want animation updates
    fileprivate var regions: [Weak<Region>] = []

    /// List of changes to execute
    fileprivate var changes: [PendingUpdate] = []

    /// Animation timer
    fileprivate var timer: Timer?

    /// Constructor is private
    fileprivate init() {

        // subscribe to raw socket messages
        BLOCKv.socket.onMessageReceivedRaw.subscribe(with: self) { descriptor in
            self.onWebSocketMessage(descriptor)
        }

    }

    /// Add a region to receive updates.
    func add(region: Region) {
        self.regions.append(Weak(value: region))
    }

    /// Stop receiving updates for the specified region.
    func remove(region: Region) {
        self.regions = self.regions.filter { !($0.value == nil || $0.value === region) }
    }

    /// Called when there's a new event message via the WebSocket.
    @objc private func onWebSocketMessage(_ descriptor: [String: Any]) {

        // we only handle state update messages here.
        guard descriptor["msg_type"] as? String == "state_update" else {
            return
        }

        // only handle brain updates
        guard let payload = descriptor["payload"] as? [String: Any],
            payload["action_name"] as? String == "brain-update" else {
            return
        }

        // get list of next positions from the brain
        guard
            let vatomID = payload["id"] as? String,
            let newObject = payload["new_object"] as? [String: Any],
            let nextPositions = newObject["next_positions"] as? [[String: Any]] else {
            return
        }

        // TODO: Ensure we care about this vatom. Check if any of our regions have this vatomID

        // map coordinates to sparse object updates
        let updates = nextPositions.map { PendingUpdate(
            time: ($0["time"] as? Double ?? 0) / 1000,
            update: DataObjectUpdateRecord(
                id: vatomID,
                changes: [
                    "vAtom::vAtomType": [
                        "geo_pos": [
                            "coordinates": $0["geo_pos"]
                        ]
                    ]
                ]
            )
            ) }

        // ensure we have any updates
        guard updates.count > 0 else {
            return
        }

        // fetch earliest time
        var earliestTime = updates[0].time
        for update in updates where earliestTime > update.time {
            earliestTime = update.time
        }

        // remove all pending changes for this object that are before our earliest time
        self.changes = self.changes.filter { !($0.update.id == vatomID && $0.time <= earliestTime) }

        // add each item to the array
        let now = Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate
        for update in updates {

            // stop if time has passed already
            if update.time < now {
                continue
            }

            // add it
            self.changes.append(update)

        }

        // sort changes oldest to newest
        self.changes.sort { $0.time - $1.time < 0 }

        // start update timer if needed
        if self.timer == nil {
            self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self,
                                              selector: #selector(doNextUpdate), userInfo: nil, repeats: true)
        }

    }

    /// Called when the timer is executed, to do the next scheduled update.
    @objc fileprivate func doNextUpdate() {

        // if there's no more updates, remove the timer and stop
        if self.changes.count == 0 {
            self.timer?.invalidate()
            self.timer = nil
            return
        }

        // check if the first entry has passed yet
        let now = Date.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate
        if self.changes[0].time > now {
            return
        }

        // make list of all changes
        var changes: [DataObjectUpdateRecord] = []
        while self.changes.count > 0 && self.changes[0].time <= now {

            // get the next change to execute
            let change = self.changes.removeFirst()

            // add to change list
            changes.append(change.update)

        }

        // execute the changes on all regions
        for region in self.regions {
            region.value?.update(objects: changes, source: .brain)
        }

    }

}

private struct PendingUpdate {
    let time: TimeInterval
    let update: DataObjectUpdateRecord
}

private class Weak<T: AnyObject> {
    weak var value: T?
    init (value: T) {
        self.value = value
    }
}
