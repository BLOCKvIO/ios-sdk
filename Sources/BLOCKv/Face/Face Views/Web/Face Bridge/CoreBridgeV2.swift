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

//FIXME: Remove temporary disable type_body_length

/// Core Bridge (Version 2.0.0)
///
/// Bridges into the Core module.
class CoreBridgeV2: CoreBridge { //swiftlint:disable:this type_body_length

    // MARK: - Enums

    /// Represents Web Face Request the contract.
    enum MessageName: String {
        // 2.0
        case initialize         = "core.init"
        case getUser            = "core.user.get"
        case getVatomChildren   = "core.vatom.children.get"
        case getVatom           = "core.vatom.get"
        case performAction      = "core.action.perform"
        case encodeResource     = "core.resource.encode"
        // 2.1
        case setVatomParent         = "core.vatom.parent.set"
        case observeVatomChildren   = "core.vatom.children.observe"
        case getCurrentUser         = "core.user.current.get"
    }

    /// Represents the Native Bridge Request contract.
    enum NativeBridgeMessageName: String {
        // 2.0
        case vatomUpdate         = "core.vatom.update"
        // 2.1
        case vatomChildrenUpdate = "core.vatom.children.update"
    }

    /// Reference to the face view which this bridge is interacting with.
    weak var faceView: WebFaceView?

    // MARK: - Initializer

    required init(faceView: WebFaceView) {
        self.faceView = faceView
    }

    /// Sends the specified vAtom to the Web Face SDK.
    ///
    /// Called on state update.
    func sendVatom(_ vatom: VatomModel) {

        guard let jsonVatom = try? JSON(encodable: vatom) else {
            printBV(error: "Unable to pass vatom update over bridge.")
            return
        }
        let payload: [String: JSON] = ["vatom": jsonVatom]

        let message = RequestScriptMessage(source: "ios-vatoms",
                                           name: NativeBridgeMessageName.vatomUpdate.rawValue,
                                           requestID: "req_x",
                                           version: "2.0.0",
                                           payload: payload)

        // fire and forget
        self.faceView?.sendRequestMessage(message, completion: nil)

    }

    /// List of vatom ids which have requested child observation.
    var childObservationVatomIds: Set<String> = []

    /// Sends the specified vAtoms to the Web Face SDK.
    func sendVatomChildren(_ vatoms: [VatomModel]) {

        // ensure observation has been requested
        guard let backingId = self.faceView?.vatom.id,
            childObservationVatomIds.contains(backingId) else {
                return
        }
        // encode vatoms
        guard let jsonVatoms = try? JSON(encodable: vatoms) else {
            printBV(error: "Unable to pass vatom update over bridge.")
            return
        }

        // create payload
        let payload: [String: JSON] = [
            "id": JSON.string(backingId),
            "vatoms": jsonVatoms
        ]
        // create message
        let message = RequestScriptMessage(source: "ios-vatoms",
                                           name: NativeBridgeMessageName.vatomChildrenUpdate.rawValue,
                                           requestID: "req_x",
                                           version: "2.1.0",
                                           payload: payload)

        // fire and forget
        self.faceView?.sendRequestMessage(message, completion: nil)

    }

    // MARK: - Web Face Requests

    /// Returns `true` if the bridge is capable of processing the message and `false` otherwise.
    func canProcessMessage(_ message: String) -> Bool {
        return !(MessageName(rawValue: message) == nil)
    }

    /// Processes the face script message and calls the completion handler with the result for encoding.
    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    func processMessage(_ scriptMessage: RequestScriptMessage,
                        completion: @escaping (Result<JSON, BridgeError>) -> Void) {

        let message = MessageName(rawValue: scriptMessage.name)!
        //printBV(info: "CoreBride_2: \(message)")

        // switch and route message
        switch message {
        case .initialize:

            self.setupBridge { result in

                switch result {
                case .success(let payload):
                    // json dance
                    guard let payload = try? JSON.init(encodable: payload) else {
                        let error = BridgeError.viewer("Unable to encode data.")
                        completion(.failure(error))
                        return
                    }
                    completion(.success(payload))

                case .failure(let error):
                    completion(.failure(error))
                }

            }

        case .getVatom:
            // ensure caller supplied params
            guard let vatomID = scriptMessage.payload["id"]?.stringValue else {
                    let error = BridgeError.caller("Missing 'id' key.")
                    completion(.failure(error))
                    return
            }
            // security check - backing vatom or first-level children
            self.permittedVatomIDs { result in

                switch result {
                case .success(let permittedIDs):

                    // check if the id is permitted to be queried
                    guard permittedIDs.contains(vatomID) else {
                        let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
                        completion(.failure(bridgeError))
                        return
                    }

                    self.getVatoms(withIDs: [vatomID], completion: { result in

                        switch result {
                        case .success(let payload):
                            // json dance
                            guard let vatom = payload["vatoms"]?.first,
                                let payload = try? JSON.init(encodable: ["vatom": vatom]) else {
                                    let error = BridgeError.viewer("Unable to encode data.")
                                    completion(.failure(error))
                                    return
                            }
                            completion(.success(payload))
                        case .failure(let error):
                            completion(.failure(error))
                        }

                    })

                case .failure:
                    let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
                    completion(.failure(bridgeError))
                }

            }

        case .getVatomChildren:
            // ensure caller supplied params
            guard let vatomID = scriptMessage.payload["id"]?.stringValue else {
                    let error = BridgeError.caller("Missing 'id' key.")
                    completion(.failure(error))
                    return
            }
            // security check - backing vatom
            guard vatomID == self.faceView?.vatom.id else {
                let error = BridgeError.caller("This method is only permitted on the backing vatom.")
                completion(.failure(error))
                return
            }
            self.discoverChildren(forVatomID: vatomID, completion: { result in

                switch result {
                case .success(let payload):
                    // json dance
                    guard
                        let vatoms = payload["vatoms"],
                        let payload = try? JSON.init(encodable: ["vatoms": vatoms]) else {
                            let error = BridgeError.viewer("Unable to encode data.")
                            completion(.failure(error))
                            return
                    }
                    completion(.success(payload))

                case .failure(let error):
                    completion(.failure(error))
                }

            })

        case .getUser:
            // ensure caller supplied params
            guard let userID = scriptMessage.payload["id"]?.stringValue else {
                    let error = BridgeError.caller("Missing 'id' key.")
                    completion(.failure(error))
                    return
            }
            self.getPublicUser(userID: userID) { result in

                switch result {
                case .success(let payload):
                    // json dance
                    guard let payload = try? JSON.init(encodable: ["user": payload]) else {
                        let error = BridgeError.viewer("Unable to encode data.")
                        completion(.failure(error))
                        return
                    }
                    completion(.success(payload))

                case .failure(let error):
                    completion(.failure(error))
                }

            }

        case .getCurrentUser:
            self.getCurrentUser { result in
                switch result {
                case .success(let payload):
                    // json dance
                    guard let payload = try? JSON.init(encodable: ["user": payload]) else {
                        let error = BridgeError.viewer("Unable to encode data.")
                        completion(.failure(error))
                        return
                    }
                    completion(.success(payload))

                case .failure(let error):
                    completion(.failure(error))
                }
            }

        case .performAction:
            // ensure caller supplied params
            guard
                let actionName = scriptMessage.payload["action_name"]?.stringValue,
                let actionPayload = scriptMessage.payload["payload"]?.objectValue,
                let thisID = actionPayload["this.id"]?.stringValue
                else {
                    let error = BridgeError.caller("Missing 'action_name' or 'payload' keys.")
                    completion(.failure(error))
                    return
            }
            // security check - backing vatom
            guard thisID == self.faceView?.vatom.id else {
                let error = BridgeError.caller("This method is only permitted on the backing vatom.")
                completion(.failure(error))
                return
            }
            // perform action
            self.performAction(name: actionName, payload: actionPayload) { result in

                switch result {
                case .success(let payload):
                    // json dance
                    guard let payload = try? JSON.init(encodable: ["user": payload]) else {
                        let error = BridgeError.viewer("Unable to encode data.")
                        completion(.failure(error))
                        return
                    }
                    completion(.success(payload))

                case .failure(let error):
                    completion(.failure(error))
                }

            }

        case .encodeResource:

            /*
             Note: Order of the array must be maintained.
             */

            // extract urls
            guard let urlStrings = scriptMessage.payload["urls"]?.arrayValue?.map({ $0.stringValue }) else {
                let error = BridgeError.caller("Missing 'urls' key.")
                completion(.failure(error))
                return
            }
            // ensure all urls are strings
            let flatURLStrings = urlStrings.compactMap { $0 }
            guard urlStrings.count == flatURLStrings.count else {
                let error = BridgeError.caller("Invalid url data type.")
                completion(.failure(error))
                return
            }
            // encode resources
            self.encodeResources(flatURLStrings) { result in

                switch result {
                case .success(let payload):
                    // json dance
                    guard let payload = try? JSON.init(encodable: ["urls": payload]) else {
                        let error = BridgeError.viewer("Unable to encode data.")
                        completion(.failure(error))
                        return
                    }
                    completion(.success(payload))

                case .failure(let error):
                    completion(.failure(error))
                }

            }

        case .setVatomParent:
            // ensure caller supplied params
            guard
                let childVatomId = scriptMessage.payload["id"]?.stringValue,
                let parentId = scriptMessage.payload["parent_id"]?.stringValue else {
                    let error = BridgeError.caller("Missing 'id' or 'parent_id' key.")
                    completion(.failure(error))
                    return
            }

            // security check - backing vatom or first-level children
            self.permittedVatomIDs { result in

                switch result {
                case .success(let permittedIDs):
                    // security check
                    if permittedIDs.contains(childVatomId) {
                        // set parent
                        self.setParentId(on: childVatomId, parentId: parentId, completion: completion)
                    } else {
                        let message = "This method is only permitted on the backing vatom or one of its children."
                        let bridgeError = BridgeError.viewer(message)
                        completion(.failure(bridgeError))
                    }
                case .failure:
                    let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
                    completion(.failure(bridgeError))
                }

            }

        case .observeVatomChildren:
            // ensure caller supplied params
            guard let vatomId = scriptMessage.payload["id"]?.stringValue else {
                let error = BridgeError.caller("Missing 'id' key.")
                completion(.failure(error))
                return
            }
            // security check - backing vatom
            guard vatomId == self.faceView?.vatom.id else {
                let error = BridgeError.caller("This method is only permitted on the backing vatom.")
                completion(.failure(error))
                return
            }
            // update observer list (this informs the native bridge to forward child updates to the WFSDK)
            childObservationVatomIds.insert(vatomId)

            // find current children
            self.discoverChildren(forVatomID: vatomId, completion: { result in

                switch result {
                case .success(let payload):
                    // json dance
                    guard
                        let vatoms = payload["vatoms"],
                        let response = try? JSON.init(encodable: ["vatoms": vatoms]) else {
                            let error = BridgeError.viewer("Unable to encode data.")
                            completion(.failure(error))
                            return
                    }
                    completion(.success(response))

                case .failure(let error):
                    completion(.failure(error))
                }

            })

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

    private struct BRCurrentUser: Encodable {

        struct Properties: Encodable {
            let firstName: String
            let lastName: String
            let avatarURI: String
            let isGuest: Bool

            enum CodingKeys: String, CodingKey { //swiftlint:disable:this nesting
                case firstName = "first_name"
                case lastName  = "last_name"
                case avatarURI = "avatar_uri"
                case isGuest   = "is_guest"
            }
        }

        struct Tokens: Encodable {
            let hasVerifiedEmail: Bool
            let hasVerifiedPhone: Bool

            enum CodingKeys: String, CodingKey {
                case hasVerifiedEmail = "has_verified_email"
                case hasVerifiedPhone = "has_verified_phone"
            }
        }

        let id: String
        let properties: Properties
        let tokens: Tokens

    }

    // MARK: - Message Handling

    /// Invoked when a face would like to create the web bridge.
    ///
    /// Creates the bridge initializtion JSON data.
    ///
    /// - Parameter completion: Completion handler to call with JSON data to be passed to the Web Face SDK.
    private func setupBridge(_ completion: @escaping (Result<BRSetup, BridgeError>) -> Void) {

        // santiy check
        guard let faceView = self.faceView else {
            let error = BridgeError.viewer("Invalid state.")
            completion(.failure(error))
            return
        }

        let vatom = faceView.vatom
        let face = faceView.faceModel
        let response = BRSetup(vatom: vatom, face: face)
        completion(.success(response))

    }

    /// Fetches the vAtom specified by the id.
    ///
    /// The method uses the vatom endpoint. Therefore, only public vAtoms are returned (irrespecitve of ownership).
    ///
    /// - Parameters:
    ///   - ids: Unique identifier of the vAtom.
    ///   - completion: Completion handler to call with JSON data to be passed to the Web Face SDK.
    private func getVatoms(withIDs ids: [String],
                           completion: @escaping (Result<[String: [VatomModel]], BridgeError>) -> Void) {

            BLOCKv.getVatoms(withIDs: ids) { result in

                switch result {
                case .success(let vatoms):
                    let response = ["vatoms": vatoms]
                    completion(.success(response))

                case .failure:
                    let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
                    completion(.failure(bridgeError))
                }

            }

    }

    /// Returns an array of vAtom IDs which are permitted to be queried.
    ///
    /// Business Rule: Only the backing vAtom or one of it's children may be queried.
    private func permittedVatomIDs(completion: @escaping (Result<[String], Error>) -> Void) {

        guard let backingID = self.faceView?.vatom.id else {
            assertionFailure("The backing vatom must be non-nil.")
            let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
            completion(.failure(bridgeError))
            return
        }

        let builder = DiscoverQueryBuilder()
        builder.setScope(scope: .parentID, value: backingID)

        BLOCKv.discover(builder) { result in

            switch result {
            case .success(let vatoms):
                // create a list of the child vatoms and add the backing (parent vatom)
                var permittedIDs = vatoms.map { $0.id }
                permittedIDs.append(backingID)
                completion(.success(permittedIDs))

            case .failure:
                let bridgeError = BridgeError.viewer("Unable to fetch vAtoms.")
                completion(.failure(bridgeError))
            }

        }

    }

    /// Searches for the children of the specifed vAtom.
    ///
    /// This method uses the discover endpoint. Therefore, *owned* and *unowned* vAtoms may be queried.
    ///
    /// - Parameters:
    ///   - id: Unique identifier of the vAtom.
    ///   - completion: Completion handler to call with JSON data to be passed to the Web Face SDK.
    private func discoverChildren(forVatomID id: String,
                                  completion: @escaping (Result<[String: [VatomModel]], BridgeError>) -> Void) {

        let builder = DiscoverQueryBuilder()
        builder.setScope(scope: .parentID, value: id)

        BLOCKv.discover(builder) { result in

            switch result {
            case .success(let vatoms):
                let response = ["vatoms": vatoms]
                completion(.success(response))
            case .failure:
                let bridgeError = BridgeError.viewer("Unable to fetch children for vAtom \(id).")
                completion(.failure(bridgeError))
            }

        }

    }

    /// Fetches the publically available properties of the user specified by the id.
    ///
    /// - Parameters:
    ///   - id: Unique identifier of the user.
    ///   - completion: Completion handler to call with JSON data to be passed to the Web Face SDK.
    private func getPublicUser(userID id: String, completion: @escaping (Result<BRUser, BridgeError>) -> Void) {

        BLOCKv.getPublicUser(withID: id) { result in

            switch result {
            case .success(let user):
                // build response
                let properties = BRUser.Properties(firstName: user.properties.firstName,
                                                   lastName: user.properties.lastName,
                                                   avatarURI: user.properties.avatarURL?.absoluteString ?? "")
                let response = BRUser(id: user.id, properties: properties)
                completion(.success(response))

            case .failure:
                let bridgeError = BridgeError.viewer("Unable to fetch public user: \(id).")
                completion(.failure(bridgeError))
            }

        }

    }

    /// Fetches the bridge-available properties of the current user.
    private func getCurrentUser(completion: @escaping (Result<BRCurrentUser, BridgeError>) -> Void) {

        var userID: String!
        var properties: BRCurrentUser.Properties!
        var tokens: BRCurrentUser.Tokens!
        var bridgeError: BridgeError?

        let group = DispatchGroup()

        group.enter()
        BLOCKv.getCurrentUser { result in

            switch result {
            case .success(let user):
                // build response
                properties = BRCurrentUser.Properties(firstName: user.firstName,
                                                      lastName: user.lastName,
                                                      avatarURI: user.avatarURL?.absoluteString ?? "",
                                                      isGuest: user.guestID.isEmpty ? false : true)
                userID = user.id

            case .failure:
                bridgeError = BridgeError.viewer("Unable to fetch current user.")
            }

            group.leave()
        }

        group.enter()
        BLOCKv.getCurrentUserTokens { result in

            switch result {
            case .success(let tokenModel):

                // check for at least one verified email
                let hasVerifiedEmail = tokenModel.contains(where: {
                    $0.properties.tokenType == "email" && $0.properties.isConfirmed == true
                })
                // check for at least one verified phone number
                let hasVerifiedPhone = tokenModel.contains(where: {
                    $0.properties.tokenType == "phone_number" && $0.properties.isConfirmed == true
                })

                tokens = BRCurrentUser.Tokens(hasVerifiedEmail: hasVerifiedEmail,
                                              hasVerifiedPhone: hasVerifiedPhone)

            case .failure:
                bridgeError = BridgeError.viewer("Unable to fetch current user.")
            }

            group.leave()

        }

        // send response once both are done
        group.notify(queue: .main) {
            if let error = bridgeError {
                completion(.failure(error))
            } else {
                let response = BRCurrentUser(id: userID, properties: properties, tokens: tokens)
                completion(.success(response))
            }
        }

    }

    /// Performs the action.
    ///
    /// - Parameters:
    ///   - name: Name of the action.
    ///   - payload: Payload to send to the server.
    ///   - completion: Completion handler to call with JSON data to be passed to the Web Face SDK.
    private func performAction(name: String, payload: [String: JSON],
                               completion: @escaping (Result<JSON, BridgeError>) -> Void) {

        do {
            /*
             HACK: Convert JSON > Data > [String: Any] (limitation of Alamofire request encoding).
             TODO: Add 'Dictionaryable' conformance to 'JSON'. This is inefficient, but will allow simpler conversion.
             */

            let data = try JSONEncoder.blockv.encode(payload)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw BridgeError.viewer("Unable to encode data.")
            }

            BLOCKv.performAction(name: name, payload: dict) { result in

                switch result {
                case .success(let payload):
                    // convert to json
                    guard let json = try? JSON(payload) else {
                        let bridgeError = BridgeError.viewer("Unable to perform action: \(name).")
                        completion(.failure(bridgeError))
                        return
                    }
                    completion(.success(json))

                case .failure(let error):
                    let bridgeError = BridgeError.viewer("Unable to perform action: \(name). \(error.localizedDescription)")
                    completion(.failure(bridgeError))
                }

            }

        } catch {
            let error = BridgeError.viewer("Unable to encode data.")
            completion(.failure(error))
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
    ///   - completion: Completion handler to call with JSON data to be passed to the Web Face SDK.
    private func encodeResources(_ urlStrings: [String],
                                 completion: @escaping (Result<[String], BridgeError>) -> Void) {

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

        completion(.success(responseURLs))
    }

    // MARK: - 2.1

    /// Sets the parent id on the specified vatom.
    ///
    /// - Parameters:
    ///   - vatomId: Identifier of the vatom whose parent id is to be set.
    ///   - parentId: Identifier of the parent vatom.
    ///   - completion: Completion handler to call with JSON data to be passed to the Web Face SDK.
    private func setParentId(on vatomId: String, parentId: String, completion: @escaping Completion) {

        // fetch from data pool
        guard let vatom = DataPool.inventory().get(id: vatomId) as? VatomModel else {
            let message = "Unable to set parent Id: \(parentId). Data Pool inventory lookup failed."
            let bridgeError = BridgeError.viewer(message)
            completion(.failure(bridgeError))
            return
        }

        // update parent id
        BLOCKv.setParentID(ofVatoms: [vatom], to: parentId) { result in
            switch result {
            case .success:
                let response: JSON = ["new_parent_id": JSON.string(parentId)]
                completion(.success(response))

            case .failure(let error):
                let message = "Unable to set parent Id: \(parentId). \(error.localizedDescription)"
                let bridgeError = BridgeError.viewer(message)
                completion(.failure(bridgeError))
            }
        }

    }

}
