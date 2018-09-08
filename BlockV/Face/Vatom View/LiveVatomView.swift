//
//  LiveVatomView.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/09/08.
//

import Foundation

/// This subclass of `VatomView`
///
/// - note:
/// This subclass should be used when a vAtom is presented in a standalone context. It should not be used with a list
/// such as a UICollectionViewCell.
///
/// Responds to the web socket and propagates the events t
public class LiveVatomView: VatomView {

    // MARK: - Properties

    // MARK: - Initialization

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

    // MARK: - Web socket

    func handleStateUpdate(vatomStateEvent: WSStateUpdateEvent) {

        print("\nViewer > State Update Event: \n\(vatomStateEvent)")

        /*
         Typically you would perfrom a localized update using the info inside of the event.
         Refreshing the inventory off the back of the Web socket event is inefficient.
         */

        // example of extracting some bool value
        if let isDropped = vatomStateEvent.vatomProperties["vAtom::vAtomType"]?["dropped"]?.boolValue {
            print("\nViewer > State Update - isDropped \(isDropped)")
        }

        // example of extracting array of float values
        if let coordinates = vatomStateEvent.vatomProperties["vAtom::vAtomType"]?["geo_pos"]?["coordinates"]?
            .arrayValue?.compactMap({ $0.floatValue }) {
            print("\nViewer > State Update - vAtom coordinates: \(coordinates)")
        }

    }

}
