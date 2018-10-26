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

    /// Called after the observer has added a child vAtom (and it's state is available).
    func vatomObserver(_ observer: VatomObserver, didAddChildVatom vatomID: String)
    /// Called after the observer has removed a child vAtom.
    func vatomObserver(_ observer: VatomObserver, didRemoveChildVatom vatomID: String)

}

//TODO: Add start and stop methods

/// This class allows any user *owned* vAtom to be observed for state changes. This includes the adding and removing of
/// child vAtoms.
///
/// On `init(vatomID:)`, this class will fetch the vAtoms remote state and then begin observing changes to the vAtom.
/// As such, soon after `init(vatomID:)` is called, the event closures may be exectured.
///
/// This class provides a simple means of observing an *owned* vAtom and its immediate children.
///
/// Handles fetching the root and child vatoms' state directly from the platform. Additionally, performs partial updates
/// using Web socket.
///
/// Restrictions:
/// - Access level: Internal
/// - vAtom ownership: Owner only
///
/// - Essentialy a wrapper around the Web socket and provides closure interfaces. This could also be a delegate...
/// - Only watches vAtom ids (does not store full vatoms - though that could be usefull).
/// - This class interfaces directly with the update stream. Note, you may receive state events before the internal
///   vatom management system (i.e. VatomInventory) has had a chance to update.
class VatomObserver {

    // MARK: - Properties

    /// Unique identifier of the root vAtom.
    private(set) var rootVatomID: String
    /// Set of unique identifiers of root's child vAtoms.
    private(set) var childVatomIDs: Set<String> = [] {
        didSet {
            let added = childVatomIDs.subtracting(oldValue)
            let removed = oldValue.subtracting(childVatomIDs)
            // notify delegate of changes
            added.forEach { self.delegate?.vatomObserver(self, didAddChildVatom: $0) }
            removed.forEach { self.delegate?.vatomObserver(self, didRemoveChildVatom: $0) }
        }
    }

    /// Delegate
    weak var delegate: VatomObserverDelegate?

    // MARK: - Initializers

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

    /// Subscribe to state updates
    private func subscribeToUpdates() {

        BLOCKv.socket.onConnected.subscribe(with: self) { [weak self] in
            self?.refresh()
        }

        BLOCKv.socket.onVatomStateUpdate.subscribe(with: self) { [weak self] stateUpdate in

            guard let `self` = self else { return }

            // - Parent ID Change

            // check for parent id changes
            if let newParentID = stateUpdate.vatomProperties["vAtom::vAtomType"]?["parent_id"]?.stringValue {

                /*
                 Use the parent ID and the known list of children to determine if a child was added or removed.
                 */

                if newParentID == self.rootVatomID {
                    // filter out duplicates
                    if !self.childVatomIDs.contains(stateUpdate.vatomId) {
                        // add 
                        self.childVatomIDs.insert(stateUpdate.vatomId)
                        // notify delegate of imminent addition
                        self.delegate?.vatomObserver(self, didAddChildVatom: stateUpdate.vatomId)
                    }
                } else {
                    /*
                     GOTCHA:
                     If for some reason, local children become out of sync with the remote there is no sensible way
                     for the client to know if a child vAtom was removed. For example, if the remote children are
                     [A, B, C] but locally the state is [A, B] and a "parent_id" change comes down for C.
                     
                     In this case, the removal of the child will not be noticied (since the child was "not" a local
                     child). To reduce the likelyhood of this, a remote state pull should be performed in cases
                     where the observer suspects remote-local sync issues, e.g. connetion drops.
                     */

                    // remove child id
                    if self.childVatomIDs.remove(stateUpdate.vatomId) != nil {
                        // notify delegate of removal
                        self.delegate?.vatomObserver(self, didRemoveChildVatom: stateUpdate.vatomId)
                    }

                }

            }

        }

    }

    // MARK: - Pull State Update

    /// Refresh root and child vatoms using remote state.
    func refresh() {
        self.updateChildVatoms()
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
            self?.childVatomIDs = Set(validChildren.map { $0.id })

        }

    }

}
