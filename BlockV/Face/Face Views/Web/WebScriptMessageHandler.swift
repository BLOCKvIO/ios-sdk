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
import WebKit

/// This extension handles the bidirectional communication between the Web Face SDK and the Native App.
///
/// Two categories of messages:
///
/// A. Messages intended to be handled by the Face View. That is, messages that the face view will need need to respond
///    to by calling into Core (e.g. vatom.init).
///
/// B. Messages intended to be handled by the Viewer (a.k.a Custom face message). These are messages that are be
///    forwarded to the Viewer (e.g. ui.scanner.open).
extension WebFaceView: WKScriptMessageHandler {

    /// Invoked when a script message is received from a webpage.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        do {
            //FIXME: This JSON constructor should move off main queue however, message.body can only be accessed on the
            // main queue. How should this be done?
            // extract payload object
            let message = try JSON(message.body)
            guard let payload = message.objectValue else {
                throw BridgeError.caller("Top-level must be an object.")
            }
            let scriptMessage = try FaceScriptMessage(descriptor: payload)
            try self.routeMessage(scriptMessage)
        } catch {
            let error = BridgeError.caller("Invalid script message.")
            self.postError(error)
        }

    }

    /// Sends a script message to the Web Face SDK.
    ///
    /// - important: The data must be json encoded.
    func postMessage(_ responseID: String, withJSONData data: Data? = nil) {

        // create script
        var script = "(window.vatomicEventReceiver || window.blockvEventReceiver).trigger('message', "
        script += "\"" + responseID + "\""
        if let data = data {
            // string-fy the json data
            if let jsonString = String(data: data, encoding: .utf8) {
                script += ", "
                script += jsonString
            } else {
                printBV(error: "Unable to convert json data into string.")
            }
        }
        script += ");"
        printBV(info: "Posting script for evaluation:\n\(script)")

        // return to main queue
        DispatchQueue.main.async {
            // inject script into the webpage
            self.webView.evaluateJavaScript(script) { (_, error) in
                guard error == nil else {
                    printBV(error: "WebFaceView: Script failed to be evaluated: \(error!.localizedDescription)")
                    return
                }
            }
        }

    }

    /// Sends an error message to the Web Face SDK.
    func postError(responseID: String = "error", _ error: BridgeError) {

        if coreBridge is CoreBridgeV1 {
            self.postMessage(responseID, withJSONData: error.bridgeDataV1)
            printBV(error: "Posting error to bridge:\n \(error.localizedDescription)")
        } else {
            self.postMessage(responseID, withJSONData: error.bridgeDataV2)
            printBV(error: "Posting error to bridge:\n \(error.localizedDescription)")
        }

    }

}

// MARK: - Web Face View + Routing

extension WebFaceView {

    /// Routes the message from the Web Face SDK to the appropriate responder.
    ///
    /// - Parameters:
    ///   - name: Unique identifier of the message.
    ///   - data: Data payload from webpage.
    ///   - completion: Completion handler to call pasing the data to be forwarded to the webpage.
    private func routeMessage(_ message: FaceScriptMessage) throws {

        print(#function)
        print("Message name: \(message.name)")
        print("Object: \(message.object)")

        var message = message

        // create bridge
        switch message.version {
        case "1.0.0": // original Face SDK
            self.coreBridge = CoreBridgeV1(faceView: self)

            /*
             Note:
             By default, Version 1.0.0 (original Face SDK) expects the native SDK to respond with the appropriate
             response ID. Some messages expect a *named* response. In the code below, the named responses are inserted.
             */
            if message.responseID.isEmpty {
                if message.name == "vatom.init" {
                    message.responseID = "vatom.init-complete"
                } else if message.name == "vatom.children.get" {
                    message.responseID = "vatom.children.get-response"
                }
            }

            /*
             Note:
             Version 1.0.0 uses a set of legacy messages. Here, these legacy viewer messages are transformed into the
             BLOCKv standardized viewer messages.
             By doing this, viewers will be unaware (a good thing) of the version of the web face sending the custom
             messages.
             */
            switch message.name {
            case "ui.map.show": message.name = "viewer.map.show"
            case "ui.qr.scan": message.name = "viewer.qr.scan"
            case "ui.vatom.show": message.name = "viewer.vatom.show"
            case "ui.scanner.show": message.name = "viewer.scanner.show"
            case "ui.browser.open": message.name = "viewer.url.open"
            case "vatom.view.close": message.name = "viewer.view.close"
            case "vatom.view.presentCard": message.name = "viewer.card.show"
            default: break
            }

        case "2.0.0":
            self.coreBridge = CoreBridgeV2(faceView: self)
        default:
            throw BridgeError.caller("Unsupported Bridge version: \(message.version)")
        }

        // sanity check
        guard let coreBridge = self.coreBridge else {
            assertionFailure("The core bridge must be created at this point.")
            return
        }

        /*
         There are 2 classes of messages:
         1. Core messages which relate to API functionality (initiated the Web Face SDK).
         2. Viewer (custom) messages which related to common face functions.
         */

        /*
         Here the work load is offloaded to a global concurrent queue. Almost all bridge work may be executed off the
         main queue. Only messages posted to the Viewer via VatomView and evaluating the javascript should done on the
         main thread to similfy the listeners life.
         */
        DispatchQueue.global().async {
            // determine appropriate responder (core or viewer)
            if coreBridge.canProcessMessage(message.name) {
                // forward to core bridge
                coreBridge.processMessage(message) { (data, error) in
                    // convert completion into a bridge message
                    if let error = error {
                        self.postError(responseID: message.responseID, error)
                    } else if let data = data {
                        self.postMessage(message.responseID, withJSONData: data)
                    } else {
                        fatalError("An error or data must be returned.")
                    }
                }
            } else {
                // forward to viewer
                DispatchQueue.main.async {
                    self.routeMessageToViewer(message)
                }
            }
        }
    }

    /// Routes the script message to the viewer and handles the response.
    private func routeMessageToViewer(_ message: FaceScriptMessage) {

        // notify the host's message delegate of the custom message from the web page
        self.delegate?.faceView(self,
                                didSendMessage: message.name,
                                withObject: message.object,
                                completion: { (json, error) in

                // handle error from viewer
                guard error == nil else {
                    // convert error into bridge error
                    self.postError(BridgeError.viewer(error!.message))
                    return
                }
                // handle no data
                guard let json = json else {
                    self.postMessage(message.responseID, withJSONData: nil)
                    return
                }
                // attempt encoding
                do {

                    /*
                     Note:
                     Accepted Viewer Payloads
                     
                     Each Web Face SDK version imposes different requirements on the structure of the JSON payload it
                     accepts:
                     - V2: Only objects.
                     - V1: Only objects and strings.
                     */

                    switch json {
                    case let .object(object):
                        let data = try JSONEncoder.blockv.encode(object)
                        self.postMessage(message.responseID, withJSONData: data)
                    case let .string(string): // backwards compatibility V1
                        guard let data = string.data(using: .utf8) else {
                            throw BridgeError.viewer("Unable to encode.")
                        }
                        self.postMessage(message.responseID, withJSONData: data)
                    default:
                        assertionFailure("Unsupported payload type.")
                        throw BridgeError.viewer("Unsupported payload type.")
                    }
                } catch {
                    let error = BridgeError.viewer("Unable to encode viewer payload.")
                    self.postError(error)
                }

        })

    }

}
