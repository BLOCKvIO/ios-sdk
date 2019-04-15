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
import GenericJSON

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
            let scriptMessage = try RequestScriptMessage(descriptor: payload)
            try self.routeMessage(scriptMessage)
        } catch {
            let error = BridgeError.caller("Invalid script message.")
            printBV(error: error.localizedDescription)
        }

    }

    /// Sends a script message to the Web Face SDK.
    ///
    /// - important: The data must be json encoded.
    func postMessage(_ responseID: String, withJSONString jsonString: String? = nil) {

        // create script
        var script = "(window.vatomicEventReceiver || window.blockvEventReceiver).trigger('message', "
        script += "\"" + responseID + "\""
        if let jsonString = jsonString {
            script += ", "
            script += jsonString
        }
        script += ");"
//        printBV(info: "Posting script for evaluation:\n\(script)")

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

    /// Convenience method to allow an object to be posted.
    ///
    /// Ideally, this function should only allow [String: Any] payloads. However, allows primative types, e.g. Bool,
    /// to be passed across as Javascript strings.
    func sendResponse(forRequestMessage message: RequestScriptMessage, result: Result<JSON, BridgeError>) {

        /*
         Note: Accepted Viewer Payloads
         
         Each Bridge SDK version imposes different requirements on the structure of the JSON payload it
         accepts:
         - V1: Objects and primatives.
         - V2: Only objects.
         */

        switch result {
        case .success(let payload):
            // create response
            var response: JSON?
            if message.version == "1.0.0" {
                response = payload
            } else {
                response = [
                    "name": try! JSON(message.name),
                    "response_id": try! JSON(message.requestID),
                    "payload": payload
                ]
            }

            // encode response
            guard let data = try? JSONEncoder.blockv.encode(response),
                let jsonString = String.init(data: data, encoding: .utf8) else {
                    // handle error
                    let error = BridgeError.viewer("Unable to encode response.")
                    self.sendResponse(forRequestMessage: message, result: .failure(error))
                    return
            }
            self.postMessage(message.requestID, withJSONString: jsonString)

        case .failure(let error):
            // create response
            var response: JSON?
            if message.version == "1.0.0" {
                response = try! JSON(error.bridgeFormatV1)
            } else {
                response = [
                    "name": try! JSON(message.name),
                    "response_id": try! JSON(message.requestID),
                    "payload": try! JSON(error.bridgeFormatV2)
                ]
            }

            // encode response
            guard let data = try? JSONEncoder.blockv.encode(response),
                let jsonString = String.init(data: data, encoding: .utf8) else {
                    // handle error
                    let error = BridgeError.viewer("Unable to encode response.")
                    self.sendResponse(forRequestMessage: message, result: .failure(error))
                    return
            }
            self.postMessage(message.requestID, withJSONString: jsonString)

        }

    }

    /// Send a request message to the Bridge SDK.
    ///
    /// The proper working of this function is dependent on the Bridge SDK being initialized.
    func sendRequestMessage(_ scriptMessage: RequestScriptMessage,
                            completion: ((ResponseScriptMessage) -> Void)?) {

        if scriptMessage.version == "1.0.0" {
            // only payload
            let payload = scriptMessage.payload
            let data = try! JSONEncoder.blockv.encode(payload)
            let jsonString = String.init(data: data, encoding: .utf8)!
            self.postMessage(scriptMessage.requestID, withJSONString: jsonString)
        } else { // 2.0.0
            let data = try! JSONEncoder.blockv.encode(scriptMessage)
            let jsonString = String.init(data: data, encoding: .utf8)!
            self.postMessage(scriptMessage.requestID, withJSONString: jsonString)
        }

        // Completion will never be called in this version.

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
    private func routeMessage(_ message: RequestScriptMessage) throws {

        print(#function)
        print("Message name: \(message.name)")
        print("Payload: \(message.payload)")

        var message = message

        // create bridge
        switch message.version {
        case "1.0.0":
            // lazily create bridge on first web face request (core.init)
            if self.coreBridge == nil {
                self.coreBridge = CoreBridgeV1(faceView: self)
            }
            // transform V1 to V2
            message = self.transformScriptMessage(message)

        case "2.0.0":
            // lazily create bridge on first web face request (core.init)
            if self.coreBridge == nil {
                self.coreBridge = CoreBridgeV2(faceView: self)
            }

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
                coreBridge.processMessage(message) { result in

                    switch result {
                    case .success(let payload):
                        // post response
                        self.sendResponse(forRequestMessage: message, result: .success(payload))
                    case .failure(let error):
                        // post response
                        self.sendResponse(forRequestMessage: message, result: .failure(error))
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
    private func routeMessageToViewer(_ message: RequestScriptMessage) {

        // notify the host's message delegate of the custom message from the web page
        self.delegate?.faceView(self,
                                didSendMessage: message.name,
                                withObject: message.payload,
                                completion: { result in
                                    switch result {
                                    case .success(let payload):
                                        self.sendResponse(forRequestMessage: message, result: .success(payload))
                                        return
                                    case .failure(let error):
                                        // transform the bridge error
                                        let bridgeError = BridgeError.viewer(error.message)
                                        self.sendResponse(forRequestMessage: message, result: .failure(bridgeError))
                                        return
                                    }
        })

    }

    /// Transforms viewer message from protocol V1 to V2.
    ///
    /// - Parameter message: Script message to transform.
    /// - Returns: Transformed script message.
    private func transformScriptMessage(_ message: RequestScriptMessage) -> RequestScriptMessage {

        var message = message
        /*
         Note:
         By default, Version 1.0.0 (original Face SDK) expects the native SDK to respond with the appropriate
         response ID. Some messages expect a *named* response. In the code below, the named responses are inserted.
         */
        if message.requestID.isEmpty {
            if message.name == "vatom.init" {
                message.requestID = "vatom.init-complete"
            } else if message.name == "vatom.children.get" {
                message.requestID = "vatom.children.get-response"
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
        case "ui.vatom.transfer": message.name = "viewer.action.send"
        case "ui.vatom.clone": message.name = "viewer.action.share"
        default: break
        }

        return message

    }

}
