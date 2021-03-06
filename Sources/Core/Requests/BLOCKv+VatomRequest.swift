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

/// This extension groups together all BLOCKv vatom requests.
extension BLOCKv {

    // MARK: - Vatoms

    /// Fetches the current user's inventory of vAtoms. The completion handler passes in an array of
    /// `VatomModel`. The array contains *packaged* vAtoms. Packaged vAtoms have their template's configured Faces
    /// and Actions as properties.
    ///
    /// - Parameters:
    ///   - id: Allows you to specify the `id` of a vAtom whose children should be returned. If a period "." is
    ///         supplied the root inventory will be retrieved (i.e. all vAtom's without a parent) - this is the
    ///         default. If a vAtom ID is passed in, only the child vAtoms are returned.
    ///   - page: The number of the page for which the vAtoms are returned. If omitted or set as
    ///           zero, the first page is returned.
    ///   - limit: Defines the number of vAtoms per response page (up to 100). If omitted or set as
    ///            zero, the max number is returned.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    ///   - vatoms: Array of *packaged* vAtoms. Packaged vAtoms have their template's registered faces and actions
    ///     action models as populated properties.
    ///   - error: BLOCKv error.
    public static func getInventory(id: String = ".",
                                    page: Int = 0,
                                    limit: Int = 0,
                                    completion: @escaping (Result<[VatomModel], BVError>) -> Void) {

        let endpoint = API.Vatom.getInventory(parentID: id, page: page, limit: limit)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                let unpackedModel = baseModel.payload
                let packedVatoms = unpackedModel.package()
                DispatchQueue.main.async {
                    completion(.success(packedVatoms))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }

    }

    /// Fetches a vatom by its identifier. The completion handler passes in a `VatomModel` that has been *packaged*.
    /// Packaged vAtoms have their template's configured Faces and Actions as properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func getVatom(withID id: String, completion: @escaping (Result<VatomModel, BVError>) -> Void) {

        let endpoint = API.Vatom.getVatoms(withIDs: [id])

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                do {
                    // model is available
                    let unpackedModel = baseModel.payload
                    let vatom = try unpackedModel.packagedSingle()
                    DispatchQueue.main.async {
                        completion(.success(vatom))
                    }
                } catch {
                    // handle error
                    DispatchQueue.main.async {
                        completion(.failure(error as! BVError)) // swiftlint:disable:this force_cast
                    }
                }

            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }

    }

    /// Fetches vAtoms by providing an array of vAtom IDs. The completion handler passes in an array of
    /// `VatomModel`. The array contains *packaged* vAtoms. Packaged vAtoms have their template's configured Faces
    /// and Actions as properties.
    ///
    /// - Parameters:
    ///   - ids: Array of vAtom IDs
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    ///   - vatoms: Array of *packaged* vAtoms. Packaged vAtoms have their template's registered faces and actions
    ///     action models as populated properties.
    ///   - error: BLOCKv error.
    public static func getVatoms(withIDs ids: [String],
                                 completion: @escaping (Result<[VatomModel], BVError>) -> Void) {

        let endpoint = API.Vatom.getVatoms(withIDs: ids)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                let unpackedModel = baseModel.payload
                let packedVatoms = unpackedModel.package()
                DispatchQueue.main.async {
                    completion(.success(packedVatoms))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }

    }

    /// Trashes the specified vAtom.
    ///
    /// This will remove the vAtom from the current user's inventory.
    ///
    /// - Parameters:
    ///   - id: Unique identifer of the vAtom.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func trashVatom(_ id: String, completion: @escaping (BVError?) -> Void) {

        let endpoint = API.Vatom.trashVatom(id)

        self.client.request(endpoint) { result in

            switch result {
            case .success:
                // model is available
                DispatchQueue.main.async {
                    completion(nil)
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(error)
                }
            }

        }

    }

    /// Sets the parent ID of the specified vatom.
    ///
    /// - Parameters:
    ///   - vatom: Vatom whose parent ID must be set.
    ///   - parentID: Unique identifier of the parent vatom.
    ///   - completion: The completion hanlder to call when the request is completed.
    ///                 This handler is executed on the main thread.
    public static func setParentID(ofVatoms vatoms: [VatomModel], to parentID: String,
                                   completion: @escaping (Result<VatomUpdateModel, BVError>) -> Void) {

        // perform preemptive action, store undo functions
        let undos = vatoms.map {
            // tuple: (vatom id, undo function)
            (id: $0.id, undo: DataPool.inventory().preemptiveChange(id: $0.id,
                                                                    keyPath: "vAtom::vAtomType.parent_id",
                                                                    value: parentID))
        }

        let ids = vatoms.map { $0.id }
        let payload: [String: Any] = [
            "ids": ids,
            "parent_id": parentID
        ]

        let endpoint = API.Vatom.updateVatom(payload: payload)

        /*
         Note: This endpoint does not fail in the typical HTTP style. It always returns 200 OK. Rather, the paylaod
         contains an array description of successful updates and errors.
         */
        BLOCKv.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):

                /*
                 # Note
                 The most likely scenario where there will be partial containment errors is when setting the parent id
                 to a container vatom of type `DefinedFolderContainerType`. However, as of writting, the server does
                 not enforce child policy rules so this always succeeds (using the current API).
                 */
                let updateVatomModel = baseModel.payload
                DispatchQueue.main.async {
                    // roll back only those failed containments
                    let undosToRollback = undos.filter { !updateVatomModel.ids.contains($0.id) }
                    undosToRollback.forEach { $0.undo() }
                    completion(.success(updateVatomModel))
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    // roll back all containments
                    undos.forEach { $0.undo() }
                    completion(.failure(error))
                }
            }

        }

    }

    /// Searches for vAtoms on the BLOCKv platform.
    ///
    /// - Parameters:
    ///   - builder: A discover query builder object. Use the builder to simplify constructing
    ///              discover queries.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    ///   - vatoms: Array of *packaged* vAtoms. Packaged vAtoms have their template's registered faces and actions
    ///       action models as populated properties.
    ///   - error: BLOCKv error.
    public static func discover(_ builder: DiscoverQueryBuilder,
                                completion: @escaping(Result<[VatomModel], BVError>) -> Void) {

        // explicitly set return type to payload
        builder.setReturn(type: .payload)
        self.discover(payload: builder.toDictionary()) { result in

            switch result {
            case .success(let discoverResult):
                // model is available
                DispatchQueue.main.async {
                    completion(.success(discoverResult.vatoms))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }
    }

    public typealias DiscoverResult = (vatoms: [VatomModel], count: Int)

    /// Performs a search for vAtoms on the BLOCKv platform.
    ///
    /// This overload of `discover` allows a raw request payload to be passed in.
    ///
    /// - Parameters:
    ///   - payload: Raw request payload in the form of a dictionary.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    ///   - result: Tuple containing the result of the discover query.
    ///     - vatoms: Array of *packaged* vAtoms. Packaged vAtoms have their template's registered faces and actions
    ///       action models as populated properties. `nil` if the return type is `count`.
    ///     - count: Number of discovered vAtoms.
    ///   - error: BLOCKv error.
    public static func discover(payload: [String: Any],
                                completion: @escaping (Result<DiscoverResult, BVError>) -> Void) {

        let endpoint = API.Vatom.discover(payload)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                let unpackedModel = baseModel.payload
                let packedVatoms = unpackedModel.package()
                DispatchQueue.main.async {
                    completion(.success((packedVatoms, packedVatoms.count)))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }

    }

    /// Performs a geo-search for vAtoms on the BLOCKv platform (i.e. vAtoms that have been
    /// dropped by the vAtom owners).
    ///
    /// You must supply two coordinates (bottom-left and top-right) which from a rectangle.
    /// This rectangle defines  the geo search region.
    ///
    ///
    /// - Parameters:
    ///   - bottomLeftLat: Bottom left latitude coordinate.
    ///   - bottomLeftLon: Bottom left longitude coordinate.
    ///   - topRightLat: Top right latitude coordinate.
    ///   - topRightLon: Top right longitude coordinte.
    ///   - filter: The vAtom filter option to apply. Defaults to "vatoms".
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    ///   - vatoms: Array of *packaged* vAtoms. Packaged vAtoms have their template's registered faces and actions
    ///     action models as populated properties.
    ///   - error: BLOCKv error.
    public static func geoDiscover(bottomLeftLat: Double,
                                   bottomLeftLon: Double,
                                   topRightLat: Double,
                                   topRightLon: Double,
                                   filter: VatomGeoFilter = .vatoms,
                                   completion: @escaping (Result<[VatomModel], BVError>) -> Void) {

        let endpoint = API.Vatom.geoDiscover(bottomLeftLat: bottomLeftLat,
                                                     bottomLeftLon: bottomLeftLon,
                                                     topRightLat: topRightLat,
                                                     topRightLon: topRightLon,
                                                     filter: filter.rawValue)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                let unpackedModel = baseModel.payload
                let packedVatoms = unpackedModel.package()
                DispatchQueue.main.async {
                    completion(.success(packedVatoms))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }

    }

    /// - Parameters:
    ///   - bottomLeftLat: Bottom left latitude coordinate.
    ///   - bottomLeftLon: Bottom left longitude coordinate.
    ///   - topRightLat: Top right latitude coordinate.
    ///   - topRightLon: Top right longitude coordinte.
    ///   - precision: Controls the density of the group distribution. Defaults to 3.
    ///                Lower values return fewer groups (with a higher vatom count) — less dense.
    ///                Higher values return more groups (with a lower vatom count) - more dense.
    ///   - filter: The vAtom filter option to apply. Defaults to "vatoms".
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func geoDiscoverGroups(bottomLeftLat: Double,
                                         bottomLeftLon: Double,
                                         topRightLat: Double,
                                         topRightLon: Double,
                                         precision: Int,
                                         filter: VatomGeoFilter = .vatoms,
                                         completion: @escaping (Result<GeoModel, BVError>) -> Void) {

        let endpoint = API.Vatom.geoDiscoverGroups(bottomLeftLat: bottomLeftLat,
                                                           bottomLeftLon: bottomLeftLon,
                                                           topRightLat: topRightLat,
                                                           topRightLon: topRightLon,
                                                           precision: precision,
                                                           filter: filter.rawValue)

        BLOCKv.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                DispatchQueue.main.async {
                    completion(.success(baseModel.payload))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }

    }

    // MARK: - Actions

    /// Fetches all the actions configured for a template.
    ///
    /// - Parameters:
    ///   - id: Unique identified of the template.
    ///   - completion: The completion handler to call when the call is completed.
    ///                 This handler is executed on the main queue.
    public static func getActions(forTemplateID id: String,
                                  completion: @escaping (Result<[ActionModel], BVError>) -> Void) {

        let endpoint = API.UserActions.getActions(forTemplateID: id)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                DispatchQueue.main.async {
                    completion(.success(baseModel.payload))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }

    }

    /// Models an action response.
    public struct ActionResponse {
        /// Name of the action.
        public let name: String
        /// Request payload.
        public let payload: [String: Any]
        /// Platform response.
        public let result: Result<[String: Any], BVError>
    }

    /// Performs an action on the BLOCKv platform.
    ///
    /// ### Notifications:
    /// - `willPerformAction` is broadcast before the request is sent to the platform to perform the action.
    /// - `didPerformAction` is broadcast after a response is received from the platform.
    ///
    /// - Parameters:
    ///   - name: Name of the action to perform, e.g. "Drop".
    ///   - payload: Body payload that will be sent as JSON in the request body.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public static func performAction(name: String,
                                     payload: [String: Any],
                                     completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        // broadcast will perform action
        NotificationCenter.default.post(name: Notification.Name.BVAction.willPerformAction,
                                        object: nil,
                                        userInfo: ["name": name, "payload": payload])

        let endpoint = API.VatomAction.custom(name: name, payload: payload)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let data):

                do {
                    guard
                        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let responsePayload = object["payload"] as? [String: Any] else {
                            throw BVError.modelDecoding(reason: "Unable to extract payload.")
                    }
                    // model is available
                    DispatchQueue.main.async {
                        // broadcast did perform action
                        let response = ActionResponse(name: name, payload: payload, result: .success(responsePayload))
                        NotificationCenter.default.post(name: Notification.Name.BVAction.didPerformAction,
                                                        object: nil,
                                                        userInfo: ["name": name, "payload": payload,
                                                                   "response": response])
                        completion(.success(payload))
                    }

                } catch {
                    DispatchQueue.main.async {
                        let error = BVError.modelDecoding(reason: error.localizedDescription)
                        // broadcast did perform action
                        let response = ActionResponse(name: name, payload: payload, result: .failure(error))
                        NotificationCenter.default.post(name: Notification.Name.BVAction.didPerformAction,
                                                        object: nil,
                                                        userInfo: ["name": name, "payload": payload,
                                                                   "response": response])
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    // broadcast did perform action
                    let response = ActionResponse(name: name, payload: payload, result: .failure(error))
                    NotificationCenter.default.post(name: Notification.Name.BVAction.didPerformAction,
                                                    object: nil,
                                                    userInfo: ["name": name, "payload": payload,
                                                               "response": response])
                    completion(.failure(error))
                }
            }

        }

    }

    // MARK: - Common Actions for Unowned vAtoms

    /// Performs an acquire action on the specified vatom id.
    ///
    /// Often, only a vAtom's ID is known, e.g. scanning a QR code with an embeded vAtom
    /// ID. This call is useful is such circumstances.
    ///
    /// - Parameters:
    ///   - id: The id of the vAtom to acquire.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public static func acquireVatom(withID id: String,
                                    completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        let body = ["this.id": id]
        // perform the action
        self.performAction(name: "Acquire", payload: body) { result in
            completion(result)
        }

    }

    /// Performs an acquire pub variation action on the specified vatom id.
    ///
    /// - Parameters:
    ///   - id: The id of the vAtom to acquire.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public static func acquirePubVariation(withID id: String,
                                           completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        let body = ["this.id": id]
        // perform the action
        self.performAction(name: "AcquirePubVariation", payload: body) { result in
            completion(result)
        }

    }

    /// Performs an dispense action on the specified vatom id.
    ///
    /// - Parameters:
    ///   - id: The id of the vatom to dispense.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public static func dispense(vatomID id: String,
                                completion: @escaping (Result<[String: Any], BVError>) -> Void) {

        let body = ["this.id": id]
        // perform the action
        self.performAction(name: "Dispense", payload: body) { result in
            completion(result)
        }
    }

    // MARK: - Redemption

    /// Performs a redemption request on the specified vatom id. This will trigger an RPC socket event to the client informing it of the redemption request.
    ///
    /// This call is intended for merchant accounts.
    ///
    /// - Parameter id: Vatom identifier for redemption.
    /// - Parameter completion: The completion handler to call when the action is completed.
    ///                         This handler is executed on the main queue.
    public static func requestRedemption(vatomID id: String, completion: @escaping (BVError?) -> Void) {

        let endpoint = API.Vatom.requestRedemption(vatomID: id)

        self.client.request(endpoint) { result in

            switch result {
            case .success:
                // model is available
                DispatchQueue.main.async {
                    completion(nil)
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(error)
                }
            }

        }

    }

}
