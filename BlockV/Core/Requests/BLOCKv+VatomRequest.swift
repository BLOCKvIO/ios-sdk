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

/// This extension groups together all BLOCKv vatom requests.
extension BLOCKv {

    // MARK: - Vatoms

    /// Fetches the current user's inventory of vAtoms. The completion handler is passed in a
    /// `PackModel` which  includes the returned vAtoms as well as the configured Faces and Actions.
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
    public static func getInventory(id: String = ".",
                                    page: Int = 0,
                                    limit: Int = 0,
                                    completion: @escaping (PackModel?, BVError?) -> Void) {

        let endpoint = API.UserVatom.getInventory(parentID: id, page: page, limit: limit)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard let packModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error!)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(packModel, nil)
            }

        }

    }

    /// Fetches vAtoms by providing an array of vAtom IDs. The response includes the vAtoms as well
    /// as the configured Faces and Actions in a `PackModel`.
    ///
    /// - Parameters:
    ///   - ids: Array of vAtom IDs
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func getVatoms(withIDs ids: [String], completion: @escaping (PackModel?, BVError?) -> Void) {

        let endpoint = API.UserVatom.getVatoms(withIDs: ids)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard let packModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error!)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(packModel, nil)
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

        let endpoint = API.UserVatom.trashVatom(id)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard baseModel?.payload.message != nil, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(error)
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
    public static func discover(_ builder: DiscoverQueryBuilder, completion: @escaping (PackModel?, BVError?) -> Void) {
        self.discover(payload: builder.toDictionary(), completion: completion)
    }

    /// Performs a search for vAtoms on the BLOCKv platform.
    ///
    /// This overload of `discover` allows a raw request payload to be passed in.
    ///
    /// - Parameters:
    ///   - payload: Raw request payload in the form of a dictionary.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func discover(payload: [String: Any], completion: @escaping (PackModel?, BVError?) -> Void) {

        let endpoint = API.VatomDiscover.discover(payload)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, handle error
            guard let packModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    print(error!.localizedDescription)
                    completion(nil, error!)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                //print(model)
                completion(packModel, nil)
            }

        }

    }

    /// Performs a geo-search for vAtoms on the BLOCKv platform (i.e. vAtoms that have been
    /// dropped by the vAtom owners).
    ///
    /// You must supply two coordinates (bottom-left and top-right) which from a rectangle.
    /// This rectangle defines  the geo search region.
    ///
    /// - Parameters:
    ///   - bottomLeftLat: Bottom left latitude coordinate.
    ///   - bottomLeftLon: Bottom left longitude coordinate.
    ///   - topRightLat: Top right latitude coordinate.
    ///   - topRightLon: Top right longitude coordinte.
    ///   - filter: The vAtom filter option to apply. Defaults to "vatoms".
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func geoDiscover(bottomLeftLat: Double,
                                   bottomLeftLon: Double,
                                   topRightLat: Double,
                                   topRightLon: Double,
                                   filter: VatomGeoFilter = .vatoms,
                                   completion: @escaping (PackModel?, BVError?) -> Void) {

        let endpoint = API.VatomDiscover.geoDiscover(bottomLeftLat: bottomLeftLat,
                                                     bottomLeftLon: bottomLeftLon,
                                                     topRightLat: topRightLat,
                                                     topRightLon: topRightLon,
                                                     filter: filter.rawValue)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, handle error
            guard let packModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    print(error!.localizedDescription)
                    completion(nil, error!)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                //print(model)
                completion(packModel, nil)
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
                                         completion: @escaping (GeoModel?, BVError?) -> Void) {

        let endpoint = API.VatomDiscover.geoDiscoverGroups(bottomLeftLat: bottomLeftLat,
                                                           bottomLeftLon: bottomLeftLon,
                                                           topRightLat: topRightLat,
                                                           topRightLon: topRightLon,
                                                           precision: precision,
                                                           filter: filter.rawValue)

        BLOCKv.client.request(endpoint) { (baseModel, error) in

            // extract model, handle error
            guard let geoGroupModels = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    print(error!.localizedDescription)
                    completion(nil, error!)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                //print(model) 
                completion(geoGroupModels, nil)
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
                                  completion: @escaping ([ActionModel]?, BVError?) -> Void) {

        let endpoint = API.UserActions.getActions(forTemplateID: id)

        self.client.request(endpoint) { (baseModel, error) in

            // extract array of actions, ensure no error
            guard let actions = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error!)
                }
                return
            }

            // data is available
            DispatchQueue.main.async {
                completion(actions, nil)
            }

        }

    }

    /// Performs an action on the BLOCKv platform.
    ///
    /// This is the most flexible of the action calls and should be used as a last resort.
    ///
    /// - Parameters:
    ///   - name: Name of the action to perform, e.g. "Drop".
    ///   - payload: Body payload that will be sent as JSON in the request body.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public static func performAction(name: String,
                                     payload: [String: Any],
                                     completion: @escaping (Data?, BVError?) -> Void) {

        let endpoint = API.VatomAction.custom(name: name, payload: payload)

        self.client.request(endpoint) { (data, error) in

            // extract data, ensure no error
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error!)
                }
                return
            }

            // data is available
            DispatchQueue.main.async {
                completion(data, nil)
            }
        }

    }

    /// Performs an acquire action on a vAtom.
    ///
    /// Often, only a vAtom's ID is known, e.g. scanning a QR code with an embeded vAtom
    /// ID. This call is useful is such circumstances.
    ///
    /// - Parameters:
    ///   - id: The id of the vAtom to acquire.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public static func acquireVatom(withID id: String,
                                    completion: @escaping (Data?, BVError?) -> Void) {

        let body = ["this.id": id]

        // perform the action
        self.performAction(name: "Acquire", payload: body) { (data, error) in
            completion(data, error)
        }

    }

}
