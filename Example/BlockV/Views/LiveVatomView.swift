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
import BLOCKv

/// Subclass of `VatomView` designed to visually represent a vAtom *and* respond to live updates to the backing vAtom.
/// To receive state updates the backing vAtom must be *owned* by the current user.
///
/// This class offers an easy way of displaying a vAtom and responding to incomming updates to the vAtom over time. This
/// class does this by listening to state updates to the backing vAtom (comming over the Web socket update stream).
///
/// The simplicity of this class comes with the drawback of **isolated** local model updates. This class will manage the
/// backing `VatomModel` in isolation (and does not propagate the changes in any way). This means if you have other UI
/// elements which are showing the same vatom, they will need to handle the state updates independently. This can lead
/// to vatom model state synchronization issues.
///
/// For this reason, we recommend using `LiveVatomView` sparingly. A better approach is to design a centralised state
/// management system (e.g vatom inventory) which keeps a single source of truth for the each of the user's vatoms. The
/// inventory should propagate it's changes to `VatomView`. This way a standard `VatomView` can be used to visually
/// represent a vAtom, without being responsible for data management.
class LiveVatomView: VatomView {

    // MARK: - Initialization
    
    override init() {
        super.init()
        commonInit()
    }

    override init(vatom: VatomModel, procedure: @escaping FaceSelectionProcedure) {
        super.init(vatom: vatom, procedure: procedure)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    /// Common initializer
    private func commonInit() {

        BLOCKv.socket.onConnected.subscribe(with: self) { [weak self] in
            // reload from remote on socket reconnect
            self?.reloadFromRemote()
        }
        
        BLOCKv.socket.onVatomStateUpdate.subscribe(with: self) { [weak self] stateUpdateEvent in
            
            // ignore other vatom updates
            guard self?.vatom?.id == stateUpdateEvent.vatomId else { return }

            // apply partial update on socket state event
            if let updatedVatom = self?.vatom?.updated(applying: stateUpdateEvent) {
                // update vatom view using updated vatom
                self?.update(usingVatom: updatedVatom)
            }
        }

    }
    
    // MARK: - Methods
    
    /// Reloads the contents of the vAtom from remote and updates vatom view.
    private func reloadFromRemote() {
        
        // get vatom id
        guard let vatomID = self.vatom?.id else { return }
        
        // fetch vatom model from remote
        BLOCKv.getVatoms(withIDs: [vatomID], completion: { (vatomModels, error) in
            
            // ensure no error
            guard error == nil, let vatom = vatomModels.first else {
                print(">>> Viewer: Unable to fetch vAtom.")
                return
            }
            
            // update vatom view using the new state of the vatom
            self.update(usingVatom: vatom)
            
        })
        
    }

}
