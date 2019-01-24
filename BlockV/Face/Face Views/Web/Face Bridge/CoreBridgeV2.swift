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

/// Core Bridge (Version 2.0.0)
///
/// Bridges into the Core module.
class CoreBridgeV2: CoreBridge {

    // MARK: - Enums

    /// Represents the contract for the Web bridge (version 2).
    enum MessageName: String {
        case initialize         = "core.init"
        case getUser            = "core.user.get"
        case getVatomChildren   = "core.vatom.children.get"
        case getVatom           = "core.vatom.get"
        case performAction      = "core.action.perform"
        case encoreResource     = "core.resource.encode"
    }

    var faceView: FaceView?

    // MARK: - Initializer

    required init(faceView: FaceView) {
        self.faceView = faceView
    }

    // MARK: - Face Brige

    /// Returns `true` if the bridge is capable of processing the message and `false` otherwise.
    func canProcessMessage(_ message: String) -> Bool {
        return !(MessageName(rawValue: message) == nil)
    }

    /// Processes the face script message and calls the completion handler with the result for encoding.
    func processMessage(_ scriptMessage: FaceScriptMessage, completion: @escaping CoreBridgeV2.Completion) {

        let message = MessageName(rawValue: scriptMessage.name)!
        printBV(info: "CoreBride_2: \(message)")

        // switch and route message
        switch message {
        case .initialize:
            self.setupBridge(completion)

        case .getVatom:
            // ensure caller supplied params
            guard let payload = scriptMessage.object["payload"]?.objectValue,
                let vatomID = payload["id"]?.stringValue else {
                    let error = BridgeError.caller("Missing 'id' key.")
                    completion(nil, error)
                    return
            }
            // security check - backing vatom or first-level children
            self.permittedVatomIDs { (permittedIDs, error) in

                // ensure no error
                guard error == nil,
                    let permittedIDs = permittedIDs,
                    // check if the id is permitted to be queried
                    permittedIDs.contains(vatomID)
                    else {
                        let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
                        completion(nil, bridgeError)
                        return
                }

                self.getVatom(withID: vatomID, completion: completion)

            }

        case .getVatomChildren:
            // ensure caller supplied params
            guard let payload = scriptMessage.object["payload"]?.objectValue,
                let vatomID = payload["id"]?.stringValue else {
                    let error = BridgeError.caller("Missing 'id' key.")
                    completion(nil, error)
                    return
            }
            // security check - backing vatom
            guard vatomID == self.faceView?.vatom.id else {
                let error = BridgeError.caller("This method is only permitted on the backing vatom.")
                completion(nil, error)
                return
            }
            self.discoverChildren(forVatomID: vatomID, completion: completion)

        case .getUser:
            // ensure caller supplied params
            guard let payload = scriptMessage.object["payload"]?.objectValue,
                let userID = payload["id"]?.stringValue else {
                    let error = BridgeError.caller("Missing 'id' key.")
                    completion(nil, error)
                    return
            }
            self.getPublicUser(userID: userID, completion: completion)

        case .performAction:
            // ensure caller supplied params
            guard
                let payload = scriptMessage.object["payload"]?.objectValue,
                let actionName = payload["action_name"]?.stringValue,
                let actionPayload = payload["payload"]?.objectValue,
                let thisID = actionPayload["this.id"]?.stringValue
                else {
                    let error = BridgeError.caller("Missing 'action_name' or 'payload' keys.")
                    completion(nil, error)
                    return
            }
            // security check - backing vatom
            guard thisID == self.faceView?.vatom.id else {
                let error = BridgeError.caller("This method is only permitted on the backing vatom.")
                completion(nil, error)
                return
            }
            // perform action
            self.performAction(name: actionName, payload: actionPayload, completion: completion)

        case .encoreResource:

            /*
             Note: Order of the array must be maintained.
             */

            // extract urls
            guard let payload = scriptMessage.object["payload"]?.objectValue,
                let urlStrings = payload["urls"]?.arrayValue?.map({ $0.stringValue }) else {
                    let error = BridgeError.caller("Missing 'urls' key.")
                    completion(nil, error)
                    return
            }
            // ensure all urls are strings
            let flatURLStrings = urlStrings.compactMap { $0 }
            guard urlStrings.count == flatURLStrings.count else {
                let error = BridgeError.caller("Invalid url data type.")
                completion(nil, error)
                return
            }

            self.encodeResources(flatURLStrings, completion: completion)

        }

    }

    // MARK: - Bridge Responses

    private struct BRSetup: Encodable {
        let vatom: VatomModel
        let face: FaceModel
    }

    private struct BRUser: Encodable {

        struct Properties: Encodable {
            let firstName: String
            let lastName: String
            let avatarURI: String

            enum CodingKeys: String, CodingKey { //swiftlint:disable:this nesting
                case firstName = "first_name"
                case lastName  = "last_name"
                case avatarURI = "avatar_uri"
            }
        }

        let id: String
        let properties: Properties

    }

    // MARK: - Message Handling

    /// Invoked when a face would like to create the web bridge.
    ///
    /// Creates the bridge initializtion JSON data.
    ///
    /// - Parameter completion: Completion handler to call with JSON data to be passed to the webpage.
    private func setupBridge(_ completion: @escaping Completion) {

        // santiy check
        guard let faceView = self.faceView else {
            let error = BridgeError.viewer("Invalid state.")
            completion(nil, error)
            return
        }

        let vatom = faceView.vatom
        let face = faceView.faceModel

        let response = BRSetup(vatom: vatom, face: face)

        // json-data encode the model
        guard let data = try? JSONEncoder.blockv.encode(response) else {
            let bridgeError = BridgeError.viewer("Unable to encode response.")
            completion(nil, bridgeError)
            return
        }
        completion(data, nil)

    }

    /// Fetches the vAtom specified by the id.
    ///
    /// The method uses the vatom endpoint. Therefore, only public vAtoms are returned (irrespecitve of ownership).
    ///
    /// - Parameters:
    ///   - ids: Unique identifier of the vAtom.
    ///   - completion: Completion handler to call with JSON data to be passed to the webpage.
    private func getVatom(withID id: String, completion: @escaping Completion) {

            BLOCKv.getVatoms(withIDs: [id]) { (vatoms, error) in

                // ensure no error, extract first vatom
                guard error == nil, let vatom = vatoms.first else {
                    let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
                    completion(nil, bridgeError)
                    return
                }

                let response = ["vatom": vatom]

                // json-data encode the model
                guard let data = try? JSONEncoder.blockv.encode(response) else {
                    let bridgeError = BridgeError.viewer("Unable to encode response.")
                    completion(nil, bridgeError)
                    return
                }
                completion(data, nil)

            }

    }

    /// Returns an array of vAtom IDs which are permitted to be queried.
    ///
    /// Business Rule: Only the backing vAtom or one of it's children may be queried.
    private func permittedVatomIDs(completion: @escaping ([String]?, Error?) -> Void) {

        guard let backingID = self.faceView?.vatom.id else {
            assertionFailure("The backing vatom must be non-nil.")
            let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
            completion(nil, bridgeError)
            return
        }

        let builder = DiscoverQueryBuilder()
        builder.setScope(scope: .parentID, value: backingID)

        BLOCKv.discover(builder) { (vatoms, error) in

            // ensure no error
            guard error == nil else {
                let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
                completion(nil, bridgeError)
                return
            }
            // create a list of the child vatoms and add the backing (parent vatom)
            var permittedIDs = vatoms.map { $0.id }
            permittedIDs.append(backingID)

            completion(permittedIDs, nil)
        }

    }

    /// Searches for the children of the specifed vAtom.
    ///
    /// This method uses the discover endpoint. Therefore, *owned* and *unowned* vAtoms may be queried.
    ///
    /// - Parameters:
    ///   - id: Unique identifier of the vAtom.
    ///   - completion: Completion handler to call with JSON data to be passed to the webpage.
    private func discoverChildren(forVatomID id: String, completion: @escaping Completion) {

        let builder = DiscoverQueryBuilder()
        builder.setScope(scope: .parentID, value: id)

        BLOCKv.discover(builder) { (vatoms, error) in

            // ensure no error
            guard error == nil else {
                let bridgeError = BridgeError.viewer("Unable to fetch children for vAtom \(id).")
                completion(nil, bridgeError)
                return
            }

            let response = ["vatoms": vatoms]

            // json-data encode the model
            guard let data = try? JSONEncoder.blockv.encode(response) else {
                let bridgeError = BridgeError.viewer("Unable to encode response.")
                completion(nil, bridgeError)
                return
            }
            completion(data, nil)

        }

    }

    /// Fetches the publically available properties of the user specified by the id.
    ///
    /// - Parameters:
    ///   - id: Unique identifier of the user.
    ///   - completion: Completion handler to call with JSON data to be passed to the webpage.
    private func getPublicUser(userID id: String, completion: @escaping Completion) {

        BLOCKv.getPublicUser(withID: id) { (user, error) in

            // ensure no error
            guard let user = user, error == nil else {
                let bridgeError = BridgeError.viewer("Unable to fetch public user: \(id).")
                completion(nil, bridgeError)
                return
            }

            // build response
            let properties = BRUser.Properties(firstName: user.properties.firstName,
                                               lastName: user.properties.lastName,
                                               avatarURI: user.properties.avatarURL?.absoluteString ?? "")
            let response = BRUser(id: user.id, properties: properties)

            // json-data encode the model
            guard let data = try? JSONEncoder.blockv.encode(response) else {
                let bridgeError = BridgeError.viewer("Unable to encode response.")
                completion(nil, bridgeError)
                return
            }
            completion(data, nil)

        }

    }

    /// Performs the action.
    ///
    /// - Parameters:
    ///   - name: Name of the action.
    ///   - payload: Payload to send to the server.
    ///   - completion: Completion handler to call with JSON data to be passed to the webpage.
    private func performAction(name: String, payload: [String: JSON], completion: @escaping Completion) {

        //FIXME: Should the bridge construct the payload or the native side?

        //NOTE: The Client networking layer uses JSONSerialisation which does not play well with JSON.
        // Options:
        // a) Client must be updated to use JSON
        // b) Right here, JSON must be converted to [String: Any] (an inefficient conversion)

        do {
            // HACK: Convert JSON to Data to [String: Any]
            let data = try JSONEncoder.blockv.encode(payload)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw BridgeError.viewer("Unable to encode data.")
            }
            BLOCKv.performAction(name: name, payload: dict) { (data, error) in
                // ensure no error
                guard let data = data, error == nil else {
                    let bridgeError = BridgeError.viewer("Unable to perform action: \(name).")
                    completion(nil, bridgeError)
                    return
                }
                completion(data, nil)
            }
        } catch {
            let error = BridgeError.viewer("Unable to encode data.")
            completion(nil, error)
        }
    }

    /// Performs an encode on the resources.
    ///
    /// If a URL cannot be encoded it is returned unmodified.
    ///
    /// Method:
    /// Asset provider credentials. This method is used over the JWT method, otherwise the JWT would be 'leaked' to the
    /// Web Face.
    ///
    /// - Parameters:
    ///   - urlStrings: Array of URL strings to be encoded (if possible).
    ///   - completion: Completion handler to call with JSON data to be passed to the webpage.
    private func encodeResources(_ urlStrings: [String], completion: @escaping Completion) {

        // convert to URL type
        let urls = urlStrings.map { URL(string: $0) }
        // map into response url array
        let responseURLs: [String] = urls.enumerated().map {
            if let url = $1 {
                // attempt encoding, otherwise fallback on origional url
                return (try? BLOCKv.encodeURL(url).absoluteString) ?? urlStrings[$0]
            } else {
                // fallback, URL convertion failed
                return urlStrings[$0]
            }
        }

        // json-data encode the model
        guard let data = try? JSONEncoder.blockv.encode(responseURLs) else {
            let bridgeError = BridgeError.viewer("Unable to encode response.")
            completion(nil, bridgeError)
            return
        }

        completion(data, nil)
    }

}
