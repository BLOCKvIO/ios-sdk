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

protocol VatomObserverDelegate: class {

    /// Called when the root vAtom has experienced a property change.
    func vatomObserver(_ observer: VatomObserver, rootVatomStateUpdated: VatomModel)
    /// Called when a child vAtom has experienced a property change.
    func vatomObserver(_ observer: VatomObserver, childVatomStateUpdated: VatomModel)

    /// Called when the observer is about to add a child vAtom.
    ///
    /// Use this event to be notified of an imminent child vAtom beign added to the root vAtom, e.g. beginning an
    /// incomming animation.
    ///
    /// To know when the child's state is available, conform to:
    /// `vatomObserver(:didAddChildVatom:)`.
    func vatomObserver(_ observer: VatomObserver, willAddChildVatom vatomID: String)
    /// Called after the observer has added a child vAtom (and it's state is available).
    func vatomObserver(_ observer: VatomObserver, didAddChildVatom childVatom: VatomModel)
    /// Called after the observer has removed a child vAtom.
    func vatomObserver(_ observer: VatomObserver, didRemoveChildVatom childVatom: VatomModel)

}

//TODO: Add start and stop methods

/// This class provides a simple means of observing an *owned* vAtom and its immediate children.
///
/// Handles fetching the root and child vatoms' state directly from the platform. Additionally, performs partial updates
/// using Web socket.
///
/// Restrictions:
/// - Access level: Internal
/// - vAtom ownership: Owner only
class VatomObserver {

    // MARK: - Typealiases

    typealias StateUpdate = (_ vatomID: String, _ whenModified: Date, _ newProperties: [String: Any]) -> Void

    // MARK: - Properties

    /// Unique identifier of the root vAtom.
    public private(set) var rootVatomID: String

    public private(set) var rootVatom: VatomModel?

    /// Set of **direct** child vAtoms.
    ///
    /// Direct children are those vAtoms whose parent ID matches the root vAtom's ID.
    public private(set) var childVatoms: Set<VatomModel> = [] {
        didSet {
            // call closures with changes
            let added = childVatoms.subtracting(oldValue)
            let removed = oldValue.subtracting(childVatoms)
            added.forEach { self.delegate?.vatomObserver(self, didAddChildVatom: $0) }
            removed.forEach { self.delegate?.vatomObserver(self, didRemoveChildVatom: $0) }
        }
    }

    /// Delegate
    weak var delegate: VatomObserverDelegate?

    // MARK: - Initialization

    /// Initialize using a vAtom ID.
    init(vatomID: String) {

        self.rootVatomID = vatomID

        // move block out of init
        DispatchQueue.main.async {
            self.refresh()
        }

        self.subscribeToUpdates()

    }

    // MARK: - Push State Update (Real-Time)

    private func subscribeToUpdates() {

        BLOCKv.socket.onConnected.subscribe(with: self) {
            self.refresh()
        }

        BLOCKv.socket.onVatomStateUpdate.subscribe(with: self) { stateUpdate in

            // - Parent ID Change

            // check for parent id changes
            if let newParentID = stateUpdate.vatomProperties["vAtom::vAtomType"]?["parent_id"]?.stringValue {

                /*
                 Use the parent ID and the known list of children to determine if a child was added or removed.
                 */

                if newParentID == self.rootVatomID {
                    // filter out duplicates
                    if !self.childVatoms.contains(where: { $0.id == stateUpdate.vatomId }) {
                        // notify delegate of imminent addition
                        self.delegate?.vatomObserver(self, willAddChildVatom: stateUpdate.vatomId)
                        // add child (async)
                        self.addChildVatom(withID: stateUpdate.vatomId)
                    }
                } else {
                    // if the vatom's parentID is not the rootID and is in the list of children
                    if let index = self.childVatoms.firstIndex(where: { $0.id == stateUpdate.vatomId }) {
                        /*
                         GOTCHA:
                         If for some reason, local children become out of sync with the remote there is no sensible way
                         for the client to know if a child vAtom was removed. For example, if the remote children are
                         [A, B, C] but locally the state is [A, B] and a "parent_id" change comes down for C.
                         
                         In this case, the removal of the child will not be noticied (since the child was "not" a local
                         child). To reduce the likelyhood of this, a remote state pull should be performed in cases
                         where the observer suspects remote-local sync issues, e.g. connetion drops.
                         */

                        // remove child vatom
                        let removedVatom = self.childVatoms.remove(at: index)
                        // notify delegate of removal
                        self.delegate?.vatomObserver(self, didRemoveChildVatom: removedVatom)
                    }
                }

            }

        }

    }

    // MARK: - Pull State Update

    /// Refresh root and child vatoms using remote state.
    public func refresh() {
        self.updateRootVatom()
        self.updateChildVatoms()
    }

    /// Fetch root vAtom's remote state.
    private func updateRootVatom() {

        BLOCKv.getVatoms(withIDs: [self.rootVatomID]) { [weak self] (vatoms, error) in

            // ensure no error
            guard let rootVatom = vatoms.first, error == nil else {
                printBV(error: "Unable to fetch root vAtom. Error: \(String(describing: error?.localizedDescription))")
                return
            }
            // update root vAtom
            self?.rootVatom = rootVatom

        }

    }

    /// Fetch remote state for the specified child vAtom and adds it to the list of children.
    private func addChildVatom(withID childID: String) {

        BLOCKv.getVatoms(withIDs: [childID]) { [weak self] (vatoms, error) in

            // ensure no error
            guard let childVatom = vatoms.first, error == nil else {
                printBV(error: "Unable to vAtom. Error: \(String(describing: error?.localizedDescription))")
                return
            }

            // ensure the vatom is still a child
            // there is a case, due to the async arch, where the retrieved vAtom may no longer be a child.
            if childVatom.props.parentID == self?.rootVatomID {
                // insert child (async)
                self?.childVatoms.insert(childVatom)
            }

        }

    }

    /// Replace all the root vAtom's direct children using remote state.
    private func updateChildVatoms() {

        BLOCKv.getInventory(id: self.rootVatomID) { [weak self] (vatoms, error) in

            // ensure no error
            guard error == nil else {
                printBV(error: "Unable to fetch children. Error: \(String(describing: error?.localizedDescription))")
                return
            }
            // ensure correct parent ID
            let validChildren = vatoms.filter { $0.props.parentID == self?.rootVatomID }
            // replace the list of children
            self?.childVatoms = Set(validChildren)

        }

    }

}
