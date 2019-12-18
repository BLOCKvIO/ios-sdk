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

//TODO: 1. Preemptive updates should be distributed to all regions.
//TODO: 2. Regions' should be able to opt into preemptive updates.

/// Extends VatomModel with common vatom actions available on owned vatoms.
///
/// Actions are *preemptive* where possible. That is, data pool is updated locally before the network request is
/// made performing the action on the server. Preemptive updates are always applied to the Inventory Region. Pickup and Drop preemtive updates
/// are applied to all regions.
extension VatomModel {

    // MARK: - Common Actions

    /// Performs the **Transfer** action on the current vatom and preeempts the action result.
    ///
    /// - Parameters:
    ///   - token: User token to which the vatom should be transferred.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func transfer(toToken token: UserToken,
                         completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        let body = [
            "this.id": self.id,
            "new.owner.\(token.type.rawValue)": token.value
        ]

        // prempt reactor outcome
        // remove vatom from inventory region
        let undoRemove = DataPool.inventory().preemptiveRemove(id: self.id)

        // perform the action
        self.performAction("Transfer", payload: body, undos: [undoRemove], completion: completion)

    }

    /// Perform the **Redeem** action on the current vatom and preeempts the action result.
    ///
    /// - Parameters:
    ///   - token: User token to which the vatom should be redeemed.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func redeem(toToken token: UserToken,
                       completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        let body = [
            "this.id": self.id,
            "new.owner.\(token.type.rawValue)": token.value
        ]

        // prempt reactor outcome
        // remove vatom from inventory region
        let undo = DataPool.inventory().preemptiveRemove(id: self.id)

        // perform the action
        self.performAction("Redeem", payload: body, undos: [undo], completion: completion)

    }

    /// Performs the **Activate** action on the current vatom and preeempts the action result.
    ///
    /// - Parameters:
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func activate(completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        let body = ["this.id": self.id]

        // prempt reactor outcome
        // remove vatom from inventory region
        let undo = DataPool.inventory().preemptiveRemove(id: self.id)

        // perform the action
        self.performAction("Activate", payload: body, undos: [undo], completion: completion)

    }

    /// Performs the **Clone** action on the current vatom and preeempts the action result.
    ///
    /// - Parameters:
    ///   - token: User token to which the vatom should be cloned.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func clone(toToken token: UserToken,
                      completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        let body = [
            "this.id": self.id,
            "new.owner.\(token.type.rawValue)": token.value
        ]

        // prempt reactor outcome

        /*
         1. `num_direct_clones` is increased by 1.
         2. `cloning_score` is dependent on the clone gain - which is not know at this point.
         */
        let undo = DataPool.inventory().preemptiveChange(id: self.id,
                                                         keyPath: "vAtom::vAtomType.num_direct_clones",
                                                         value: self.props.numberDirectClones + 1)

        // perform the action
        self.performAction("Clone", payload: body, undos: [undo], completion: completion)

    }

    /// Performs the **Drop** action on the current vatom and preeempts the action result.
    ///
    /// - Parameters:
    ///   - longitude: The longitude component of the coordinate.
    ///   - latitude: The latitude component of the coordinate.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func dropAt(longitude: Double,
                       latitude: Double,
                       completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        let body: [String: Any] = [
            "this.id": self.id,
            "geo.pos": [
                "Lat": latitude,
                "Lon": longitude
            ]
        ]

        var undos: [Region.UndoFunction] = []
        // preempt reactor outcome
        DataPool.regions.forEach {
            undos.append($0.preemptiveChange(id: self.id,
                                             keyPath: "vAtom::vAtomType.geo_pos.coordinates",
                                             value: [longitude, latitude]))

            undos.append($0.preemptiveChange(id: self.id,
                                             keyPath: "vAtom::vAtomType.dropped",
                                             value: true))
        }

        // perform the action
        self.performAction("Drop", payload: body, undos: undos, completion: completion)

    }

    /// Performs the **Pickup** action on the current vatom and preeempts the action result.
    ///
    ///   - completion: The completion handler to call when the action is completed.
    ///              This handler is executed on the main queue.
    public func pickUp(completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        let body = ["this.id": self.id]

        var undos: [Region.UndoFunction] = []
        // perform reactor outcome
        DataPool.regions.forEach {
            undos.append($0.preemptiveChange(id: self.id, keyPath: "vAtom::vAtomType.dropped", value: false))
        }

        // perform the action
        self.performAction("Pickup", payload: body, undos: undos, completion: completion)

    }
    
    /// Performs the **Split** action on the current vatom and preempts the result.
    ///
    /// - Parameters:
    ///   - vatomIds: Array of vatom ids to be split off this parent. The vatoms are moved up one level.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func split(vatomIds: [String], completion: ((Result<[String: Any], BVError>) -> Void)?) {
        
        let body: [String: Any] = ["this.id": self.id,
                                   "vatom.ids": vatomIds]
        
        // prempt reactor outcome
        var undos = [Region.UndoFunction]()
        for id in vatomIds {
            // update parent id to self's parent id (i.e. move up one level).
            let undo = DataPool.inventory().preemptiveChange(id: id, keyPath: "vAtom::vAtomType.parent_id",
                                                             value: self.props.parentID)
            undos.append(undo)
        }
        
        // perform the action
        self.performAction("Split", payload: body, undos: undos, completion: completion)
    }
    
    /// Performs the **Combine** action on the current vatom and preempts the result.
    ///
    /// - Parameters:
    ///   - vatomId: Vatom id of the child vatom to combine with this vatom (i.e. parent).
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func combine(vatomId: String, completion: ((Result<[String: Any], BVError>) -> Void)?) {
        
        let body: [String: Any] = ["this.id": self.id,
                                   "child.id": vatomId]
        // update the child's parent id to be self's id
        let undo = DataPool.inventory().preemptiveChange(id: vatomId, keyPath: "vAtom::vAtomType.parent_id",
                                                         value: self.id)
        // perform the action
        self.performAction("Combine", payload: body, undos: [undo], completion: completion)
        
    }

    private typealias Undo = () -> Void

    /// Performs the action and rolls back unsing the undo functions if an error occurs.
    ///
    /// - Parameters:
    ///   - name: Name of the action, e.g. "Transfer".
    ///   - payload: Action payload
    ///   - undos: Array of undo closures. If the action fails, each undo closure will be executed.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    private func performAction(_ name: String,
                               payload: [String: Any],
                               undos: [Undo] = [],
                               completion: ((Result<[String: Any], BVError>) -> Void)?) {

        /// passed in vatom id must match `this.id`
        guard let vatomId = payload["this.id"] as? String, self.id == vatomId else {
            let error = BVError.custom(reason: "Invalid payload. Value `this.id` must be match the current vAtom.")
            completion?(.failure(error))
            return
        }

        // update 'when_modified' date
        let nowDate = DateFormatter.blockvDateFormatter.string(from: Date())
        let undoModified = DataPool.inventory().preemptiveChange(id: self.id, keyPath: "when_modified", value: nowDate)
        var allUndos = undos
        allUndos.append(undoModified)

        // perform the action
        BLOCKv.performAction(name: name, payload: payload) { result in

            switch result {
            case .success(let payload):
                completion?(.success(payload))

            case .failure(let error):
                // run undo closures
                allUndos.forEach { $0() }
                completion?(.failure(error))
            }

        }

    }

}
