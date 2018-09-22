//
//  WebFaceView.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/09/07.
//

import Foundation

/// Contains the interface to the Web.
///
/// Should this be an enum?
enum WebInterface: String {
    case vatomInit          = "vatom.init"
    case getVatomChildren   = "vatom.children.get"
    case performAction      = "vatom.performAction"
}

/// Native Web face view.
///
/// Displays a web face
class WebFaceView: FaceView {

    /*
     Goals:
     
     Communication between the Web App and the Web face is bidirectional.
     
     1. Face View > Web App
     - Vatom Update (e.g. off the back of the Web socket).
      - This is the only message that goes in this direction.
     
     2. Web App > Face View
     - The bulk of the communication is initiated by the Web app.
     
     There 2 categories of messages:
     
     2A. Messages intended to be handled by the Face View.
     That is, messages that the face view will need need to respond to by calling into Core. E.g getVatom.
     
     2B. Messages intended to be handled by the Viewer (that are passed via the Face View). That is, messages that
     must be forwarded to the viewer, e.g. Open scanner.
     
     */

    class var displayURL: String { return "http://*" }

    func load(completion: ((Error?) -> Void)?) {
        //
    }

    func vatomUpdated(_ vatom: VatomModel) {
        //
    }

    func unload() {
        //
    }

}
