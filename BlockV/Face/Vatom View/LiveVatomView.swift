//
//  LiveVatomView.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/09/08.
//

import Foundation
import Signals

/// This subclass of `VatomView`
///
/// - note:
/// This subclass should be used when a vAtom is presented in a standalone context. It should not be used with a list
/// such as a UICollectionViewCell.
///
/// Responds to the web socket and propagates the events through to the face view.
public class LiveVatomView: VatomView {

    // MARK: - Properties

    // MARK: - Initializer

    /// Initializes with a `VatomModel` and a `FaceSelectionProcedure`.
    public override init(vatom: VatomModel, procedure: @escaping FaceSelectionProcedure) {
        super.init(vatom: vatom, procedure: procedure)

        commonInit()
    }

    /// Initializes with a `NSCoder`.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    /// Common initializer
    private func commonInit() {

        BLOCKv.socket.connect()

        // MARK: - State Update

        // subscribe to vatom state update events
        BLOCKv.socket.onVatomStateUpdate.subscribe(with: self) { [weak self] vatomStateEvent in
            self?.handleStateUpdate(vatomStateEvent: vatomStateEvent)
        }

    }

    deinit {

        // TODO: Remove signal (if necessary)?

    }

    // MARK: - Web socket

    /*
     FXIME:
     There is a point about efficiency here.
     
     1. `WebSocketManager` is receiving data, converting it to text.
     2. `WebSocketManager` then converts the text to data, the data into a `WSStateUpdateEvent` (which init the generic
     json).
     3. Here in the update method, we then extract properties out of the `WSStateUpdateEvent`'s generic JSON to update
     the properties.
     
     A more efficient solution would be to init a VatomProperties object from raw, and update the properties of the
     VatomModel. This would save generic json piece; this would also allow common bits of init(decode) for VatomModel.
     */
    func handleStateUpdate(vatomStateEvent: WSStateUpdateEvent) {

        print("\nViewer > State Update Event: \n\(vatomStateEvent)")

        // create a copy with which to mutate
        guard var vatomCopy = self.vatom else { return }

        // perform a localized update of the vatom
        vatomCopy.updateWithStateUpdate(vatomStateEvent)

        // ask vAtom view to update it self with the
        self.update(usingVatom: vatomCopy)

    }

}
