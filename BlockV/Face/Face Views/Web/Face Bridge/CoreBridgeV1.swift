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

/// Core Bridge (Version 1.0.0)
///
/// Bridges into the Core module.
class CoreBridgeV1: CoreBridge {

    func sendVatom(_ vatom: VatomModel) {

        guard
            let vatom = self.formatVatoms([vatom]).first,
            let jsonVatom = try? JSON(encodable: vatom) else {
                printBV(error: "Unable to pass vatom update over bridge.")
                return
        }
        // send the vatom accross
        let uuid = UUID().uuidString
        let payload: [String: JSON] = ["vatom": jsonVatom]

        let message = RequestScriptMessage(source: "ios-vatoms",
                                           name: "vatom.updated",
                                           requestID: "req_\(uuid)",
                                           version: "1.0.0",
                                           payload: payload)

        // fire and forget
        self.faceView?.sendRequestMessage(message, completion: nil)

    }

    // MARK: - Enums

    /// Represents the contract for the Web bridge (version 1).
    enum MessageName: String {
        case initialize         = "vatom.init"
        case getVatom           = "vatom.get"
        case getVatomChildren   = "vatom.children.get"
        case performAction      = "vatom.performAction"
        case getUserProfile     = "user.profile.fetch"
        case getUserAvatar      = "user.avatar.fetch"
    }

    // MARK: - Properties

    /// Reference to the face view which this bridge is interacting with.
    weak var faceView: WebFaceView?

    // MARK: - Initializer

    required init(faceView: WebFaceView) {
        self.faceView = faceView
    }

    // MARK: - Face Brige

    /// Returns `true` if the bridge is capable of processing the message and `false` otherwise.
    func canProcessMessage(_ message: String) -> Bool {
        if MessageName(rawValue: message) == nil {
            return false
        }
        return true
    }

    // swiftlint:disable cyclomatic_complexity

    /// Processes the face script message and calls the completion handler with the result for encoding.
    func processMessage(_ scriptMessage: RequestScriptMessage, completion: @escaping Completion) {

        /*
         Sanity Check
         Explict force unwrap - the program is in an invalid state if the message cannot be created.
         */
        let message = MessageName(rawValue: scriptMessage.name)!
        printBV(info: "CoreBride_1: \(message)")

        // switch and route message
        switch message {
        case .initialize:
            self.setupBridge(completion)

        case .getVatom:
            // ensure caller supplied params
            guard let vatomID = scriptMessage.payload["id"]?.stringValue else {
                let error = BridgeError.caller("Missing vAtom ID.")
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
            guard let vatomID = scriptMessage.payload["id"]?.stringValue else {
                let error = BridgeError.caller("Missing vAtom ID.")
                completion(nil, error)
                return
            }
            // security check
            guard vatomID == self.faceView?.vatom.id else {
                let error = BridgeError.caller("This method is only permitted on the backing vatom: \(vatomID).")
                completion(nil, error)
                return
            }
            self.discoverChildren(forVatomID: vatomID, completion: completion)

        case .getUserProfile:
            // ensure caller supplied params
            guard let userID = scriptMessage.payload["userID"]?.stringValue else {
                let error = BridgeError.caller("Missing user ID.")
                completion(nil, error)
                return
            }
            self.getPublicUser(forUserID: userID, completion: completion)

        case .getUserAvatar:
            // ensure caller supplied params
            guard let userID = scriptMessage.payload["userID"]?.stringValue else {
                let error = BridgeError.caller("Missing user ID.")
                completion(nil, error)
                return
            }
            self.getPublicAvatarURL(forUserID: userID, completion: completion)

        case .performAction:
            // ensure caller supplied params
            guard
                let actionName = scriptMessage.payload["actionName"]?.stringValue,
                let actionData = scriptMessage.payload["actionData"]?.objectValue,
                let thisID = actionData["this.id"]?.stringValue
                else {
                    let error = BridgeError.caller("Invalid payload.")
                    completion(nil, error)
                    return
            }
            // security check - backing vatom
            guard thisID == self.faceView?.vatom.id else {
                let error = BridgeError.caller("This method is only permitted for the backing vatom.")
                completion(nil, error)
                return
            }

            self.performAction(name: actionName, payload: actionData, completion: completion)
        }

    }

    // MARK: - Bridge Responses

    private struct BRSetup: Encodable {
        let viewMode: String
        let user: BRUser
        let vatomInfo: BRVatom
        let viewer: [String: String] = [:]
    }

    private struct BRVatom: Encodable {
        let id: String
        let properties: JSON
        let resources: [String: URL]
    }

    private struct BRUser: Encodable {
        let id: String
        let firstName: String
        let lastName: String
        let avatarURL: String
    }

    // MARK: - Message Handling

    /// Invoked when a face would like to create the web bridge.
    ///
    /// Creates the bridge initializtion JSON data.
    ///
    /// - Parameter completion: Completion handler to call with JSON data to be passed to the webpage.
    private func setupBridge(_ completion: @escaping CoreBridge.Completion) {

        // santiy check
        guard let faceView = self.faceView else {
            let error = BridgeError.viewer("Invalid state.")
            completion(nil, error)
            return
        }

        // view mode
        let viewMode = faceView.faceModel.properties.constraints.viewMode

        // async fetch current user
        BLOCKv.getCurrentUser { [weak self] (user, error) in

            // ensure no error
            guard let user = user, error == nil else {
                let bridgeError = BridgeError.viewer("Unable to fetch current user.")
                completion(nil, bridgeError)
                return
            }
            // encode url
            var encodedURL: URL?
            if let url = user.avatarURL {
                encodedURL = try? BLOCKv.encodeURL(url)
            }
            // build user
            let userInfo = BRUser(id: user.id,
                                  firstName: user.firstName,
                                  lastName: user.lastName,
                                  avatarURL: encodedURL?.absoluteString ?? "")

            // fetch backing vAtom
            self?.getVatomsFormatted(withIDs: [faceView.vatom.id], completion: { (vatoms, error) in

                // ensure no error
                guard error == nil else {
                    let bridgeError = BridgeError.viewer("Unable to fetch backing vAtom.")
                    completion(nil, bridgeError)
                    return
                }
                // ensure a single vatom
                guard let firstVatom = vatoms.first else {
                    let bridgeError = BridgeError.viewer("Unable to fetch backing vAtom.")
                    completion(nil, bridgeError)
                    return
                }
                // create bridge response
                let vatomInfo = BRVatom(id: firstVatom.id,
                                        properties: firstVatom.properties,
                                        resources: firstVatom.resources)
                let response = BRSetup(viewMode: viewMode,
                                       user: userInfo,
                                       vatomInfo: vatomInfo)

                do {
                    // json encode the model
                    let json = try JSON.init(encodable: response)
                    completion(json, nil)
                } catch {
                    let bridgeError = BridgeError.viewer("Unable to encode response.")
                    completion(nil, bridgeError)
                }

            })

        }

    }

    /// Fetches the vAtom specified by the id.
    private func getVatom(withID id: String, completion: @escaping Completion) {

        self.getVatomsFormatted(withIDs: [id]) { (formattedVatoms, error) in

            // ensure no error
            guard error == nil else {
                completion(nil, error!)
                return
            }
            // ensure there is at least one vatom
            guard let formattedVatom = formattedVatoms.first else {
                completion(nil, BridgeError.viewer("vAtom not found."))
                return
            }
            let response = ["vatomInfo": formattedVatom]

            do {
                // json encode the model
                let json = try JSON.init(encodable: response)
                completion(json, nil)
            } catch {
                let bridgeError = BridgeError.viewer("Unable to encode response.")
                completion(nil, bridgeError)
            }

        }

    }

    /// Searched for the children of the specifed vAtom.
    ///
    /// This method uses the discover endpoint. Therefore, *owned* and *unowned* vAtoms may be returned.
    private func discoverChildren(forVatomID id: String, completion: @escaping Completion) {

        self.discoverChildrenFormatted(forVatomID: id) { (formattedVatoms, error) in

            // ensure no error
            guard error == nil else {
                completion(nil, error!)
                return
            }
            let vatomItems = formattedVatoms.map { ["vatomInfo": $0] }
            let response = ["items": vatomItems]
            do {
                // json encode the model
                let json = try JSON.init(encodable: response)
                completion(json, nil)
            } catch {
                let bridgeError = BridgeError.viewer("Unable to encode response.")
                completion(nil, bridgeError)
            }
        }

    }

    /// Fetches the publically available properties of the user specified by the id.
    private func getPublicUser(forUserID id: String, completion: @escaping Completion) {

        BLOCKv.getPublicUser(withID: id) { (user, error) in

            // ensure no error
            guard let user = user, error == nil else {
                let bridgeError = BridgeError.viewer("Unable to fetch public user: \(id).")
                completion(nil, bridgeError)
                return
            }
            // encode url
            var encodedURL: URL?
            if let url = user.properties.avatarURL {
                encodedURL = try? BLOCKv.encodeURL(url)
            }
            // build response
            let response = BRUser(id: user.id,
                                  firstName: user.properties.firstName,
                                  lastName: user.properties.lastName,
                                  avatarURL: encodedURL?.absoluteString ?? "")

            do {
                // json encode the model
                let json = try JSON.init(encodable: response)
                completion(json, nil)
            } catch {
                let bridgeError = BridgeError.viewer("Unable to encode response.")
                completion(nil, bridgeError)
            }

        }

    }

    private struct PublicAvatarFormat: Encodable {
        let id: String
        let avatarURL: String
    }

    /// Fetches the avatar URL of the user specified by the id.
    private func getPublicAvatarURL(forUserID id: String, completion: @escaping Completion) {

        BLOCKv.getPublicUser(withID: id) { (user, error) in

            // ensure no error
            guard let user = user, error == nil else {
                let bridgeError = BridgeError.viewer("Unable to fetch public user: \(id).")
                completion(nil, bridgeError)
                return
            }
            // encode url
            var encodedURL: URL?
            if let url = user.properties.avatarURL {
                encodedURL = try? BLOCKv.encodeURL(url)
            }
            // create avatar response
            let response = PublicAvatarFormat(id: user.id, avatarURL: encodedURL?.absoluteString ?? "")

            do {
                // json encode the model
                let json = try JSON.init(encodable: response)
                completion(json, nil)
            } catch {
                let bridgeError = BridgeError.viewer("Unable to encode response.")
                completion(nil, bridgeError)
            }

        }

    }

    /// Performs the action.
    private func performAction(name: String, payload: [String: JSON], completion: @escaping Completion) {

        do {
            /*
             HACK: Convert JSON > Data > [String: Any] (limitation of Alamofire request encoding).
             TODO: Add 'Dictionaryable' conformance to 'JSON'. This is inefficient, but will allow simpler conversion.
             */

            let data = try JSONEncoder.blockv.encode(payload)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw BridgeError.viewer("Unable to encode data.")
            }

            BLOCKv.performAction(name: name, payload: dict) { (payload, error) in
                // ensure no error
                guard let payload = payload, error == nil else {
                    let bridgeError = BridgeError.viewer("Unable to perform action: \(name).")
                    completion(nil, bridgeError)
                    return
                }
                // convert to json
                let json = try? JSON(payload)
                completion(json, nil)
            }

        } catch {
            let error = BridgeError.viewer("Unable to encode data.")
            completion(nil, error)
        }

    }

}

// MARK: - Helpers

/*
 Vatoms are represented in a specific way in Face Bridge 1. These helpers convert the SDKs completion types
 into the Bridge Response (BR) completion types.
 */
private extension CoreBridgeV1 {

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

    /// Completes with the vAtom in bridge format.
    private typealias BFVatomCompletion = (_ formattedVatoms: [BRVatom], _ error: BridgeError?) -> Void

    /// Fetches the vAtom and completes with the *bridge format* representation.
    ///
    /// The method uses the vatom endpoint. Therefore, only public vAtoms are returned (irrespecitve of ownership).
    private func getVatomsFormatted(withIDs ids: [String], completion: @escaping BFVatomCompletion) {

        BLOCKv.getVatoms(withIDs: ids) { (vatoms, error) in

            // ensure no error
            guard error == nil else {
                let bridgeError = BridgeError.viewer("Unable to fetch backing vAtom.")
                completion([], bridgeError)
                return
            }

            // convert vAtom into bridge format
            completion(self.formatVatoms(vatoms), nil)

        }

    }

    /// Fetches the children for the specifed vAtom.
    ///
    /// Uses the discover endpoint, so *un-owned* vAtoms may be queried.
    private func discoverChildrenFormatted(forVatomID id: String, completion: @escaping BFVatomCompletion) {

        let builder = DiscoverQueryBuilder()
        builder.setScope(scope: .parentID, value: id)

        BLOCKv.discover(builder) { (vatoms, error) in

            // ensure no error
            guard error == nil else {
                let bridgeError = BridgeError.viewer("Unable to fetch children for vAtom \(id).")
                completion([], bridgeError)
                return
            }
            // format vatoms
            completion(self.formatVatoms(vatoms), nil)

        }

    }

    /// Returns the vatom transformed into the bridge format.
    ///
    /// Resources are encoded.
    private func formatVatoms(_ vatoms: [VatomModel]) -> [BRVatom] {

        var formattedVatoms = [BRVatom]()
        for vatom in vatoms {
            // combine root and private props
            if let properties = try? JSON(encodable: vatom.props) {
                if let privateProps = vatom.private {
                    // merge private properties into root properties
                    let combinedProperties = properties.updated(applying: privateProps)
                    // encode resource urls
                    var encodedResources: [String: URL] = [:]
                    vatom.props.resources.forEach { encodedResources[$0.name] = $0.encodedURL()}
                    let vatomF = BRVatom(id: vatom.id,
                                         properties: combinedProperties,
                                         resources: encodedResources)
                    formattedVatoms.append(vatomF)
                }
            } else {
                printBV(error: "vAtom to JSON failed: vAtom: \(vatom.id).")
            }

        }
        return formattedVatoms
    }

}

extension VatomResourceModel {

    /// Returns the resource formatted and encoded for the bridge.
    fileprivate func encodedURL() -> URL {
        return (try? BLOCKv.encodeURL(self.url)) ?? self.url
    }

}
