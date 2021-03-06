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
import GenericJSON

/// Protocol to which face bridges should conform.
///
/// The Core Bridge is a layer which manages communication between the core module and the webpage (built on the Web
/// Face SDK) being rendered by the WebFaceView.
protocol CoreBridge {

    /// Completion type used by message handlers.
    ///
    /// - parameters:
    ///   - payload: Payload portion of the response.
    ///   - error: Any error encountered during message processing.
    typealias Completion = (Result<JSON, BridgeError>) -> Void

    /// Processes the message and calls the completion handler once the output is known.
    ///
    /// - Parameters:
    ///   - scriptMessage: The face script message from the webpage.
    ///   - completion: The completion handler that is called once the message has been processed.
    /// - Returns: `true` is the bridge is capable of processing the message. `false` otherwise.
    func processMessage(_ scriptMessage: RequestScriptMessage, completion: @escaping Completion)

    /// Returns `true` if the bridge is capable of processing the message and `false` otherwise.
    func canProcessMessage(_ message: String) -> Bool

    /// Sends a Vatom over the native bridge.
    ///
    /// This is to specialized for a protocol. Surely something more generic exists.
    func sendVatom(_ vatom: VatomModel)

    /// Sends the vatoms over the native bridge informing the web face of changes to the backing vatom's first-level
    /// children.
    func sendVatomChildren(_ vatoms: [VatomModel])

    /// Reference to the face view which this bridge is interacting with.
    ///
    /// Declare as `weak` to avoid retain cycle.
    var faceView: WebFaceView? { get }

}

// MARK: - Errors

/// Models the errors which may arise during bridge message communication.
enum BridgeError: Error, LocalizedError {

    /// An error casued by an issue on the viewer (native) app side.
    case viewer(_ message: String)
    /// An error caused by an issue on the caller (web face) side.
    case caller(_ message: String)

    // Version 1

    /// Returns the error formatted as a dictionary. This dictionary may be serialized into JSON data to be posted
    /// over the web bridge.
    var bridgeFormatV1: [String: String] {
        switch self {
        case let .viewer(message): return ["errorCode": "viewer_error", "errorMessage": message]
        case let .caller(message): return ["errorCode": "caller_error", "errorMessage": message]
        }
    }

    /// Data encoded version of the error.
    var bridgeDataV1: Data {
        let data = try! JSONEncoder.blockv.encode(self.bridgeFormatV1)
        return data
    }

    // Verion 2

    /// Returns the error formatted as a dictionary. This dictionary may be serialized into JSON data to be posted
    /// over the web bridge.
    var bridgeFormatV2: [String: String] {
        switch self {
        case let .viewer(message): return ["error_code": "viewer_error", "error_message": message]
        case let .caller(message): return ["error_code": "caller_error", "error_message": message]
        }
    }

    /// Data encoded version of the error.
    var bridgeDataV2: Data {
        let data = try! JSONEncoder.blockv.encode(self.bridgeFormatV2)
        return data
    }

    var localizedDescription: String {
        switch self {
        case let .viewer(message): return "Viewer Error: \(message)"
        case let .caller(message): return "Caller Error: \(message)"
        }
    }
}
