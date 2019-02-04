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

/// Struct representing a request script message. The Bridge SDK is bi-directional. This means a `RequestScriptMessage`
/// can be sent and received.
struct RequestScriptMessage: Codable {
    /// Unique identifier of the incomming message.
    var name: String
    /// Unique indentifier for the outgoing response.
    var requestID: String
    /// Origin of the message.
    let source: String
    /// Interface version being requested from the FaceSDK.
    ///
    /// If a "version" key is not present in the message it will default to 1.0.0. This fallback is the intendend to be
    /// used by first Face SDK only – all newer version MUST supply a version key-pair.
    let version: String
    /// Object containg data from the FaceSDK.
    let payload: [String: JSON]

    /// Initializes using parameters.
    init(source: String, name: String, requestID: String?, version: String?, payload: [String: JSON]?) {
        self.source = source
        self.name = name
        self.requestID = requestID ?? ""
        self.version = version ?? "1.0.0" // default for original Face SDK.
        self.payload = payload ?? [:]
    }

    /// Initializes using a JSON object.
    init(descriptor: [String: JSON]) throws {
        // extract source
        guard let source = descriptor["source"]?.stringValue, (source == "blockv_face_sdk" || source == "Vatom") else {
            throw FaceScriptError.invalidSource
        }
        // extract name
        guard let name = descriptor["name"]?.stringValue else {
            throw FaceScriptError.invalidName
        }
        // extract info
        let version = descriptor["version"]?.stringValue
        // note: 1.0.0 uses slightly different naming (responseID)
        let requestID = descriptor["request_id"]?.stringValue ?? descriptor["responseID"]?.stringValue ?? ""
        let payload = descriptor["payload"]?.objectValue ?? descriptor["data"]?.objectValue

        self.init(source: source, name: name, requestID: requestID, version: version, payload: payload)
    }

    enum FaceScriptError: Error {
        case invalidName
        case invalidSource
        case invalidVersion
    }
}

/// Struct representing a response script message. The Bridge SDK is bi-directional.
/// This means a `ResponseScriptMessage` can be sent and received.
///
/// V2 defines a wrapping payload structure.
struct ResponseScriptMessage: Encodable {

    let name: String
    let responseID: String
    let payload: JSON

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case responseID  = "response_id"
        case payload = "payload"
    }

}
