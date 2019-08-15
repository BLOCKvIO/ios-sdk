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
import Alamofire

/// Consolidates BLOCKv API endpoints.
/// Endpoints closely match their server counterparts where possible.
/// The goal is to abstract endpoint specific details. The networking client should not need to taylor requests for the
/// specific of an endpoint.

enum API { }

extension API {

    /// Namespace for endpoints which are generic over their response type.
    enum Generic {

        private static let userVatomPath    = "/v1/user/vatom"
        private static let userActionsPath  = "/v1/user/actions"
        private static let actionPath       = "/v1/user/vatom/action"
        private static let userActivityPath = "/v1/activity"

        // MARK: OAuth

        /// Builds the generic endpoint to exchange a code for tokens.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func token<T>(grantType: String, clientID: String, code: String, redirectURI: String) -> Endpoint<T> {

            let params: [String: Any] = [
                "grant_type": grantType,
                "client_id": clientID,
                "code": code,
                "redirect_uri": redirectURI
            ]

            return Endpoint(method: .post,
                            path: "/v1/oauth/token",
                            parameters: params)
        }

        // MARK: Asset Providers

        static func getAssetProviders<T>() -> Endpoint<T> {
            return Endpoint(method: .get,
                            path: "/v1/user/asset_providers")
        }

        // MARK: Vatoms

        /// Builds the generic endpoint to get the current user's inventory vatom's sync number.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getInventoryVatomSyncNumbers<T>(limit: Int = 1000, token: String) -> Endpoint<T> {
            return Endpoint(method: .get,
                            path: userVatomPath + "/inventory/index",
                            parameters: ["limit": limit, "next_token": token],
                            encoding: URLEncoding.queryString)
        }

        /// Builds the generic endpoint to get the current user's inventory sync hash.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getInventoryHash<T>() -> Endpoint<T> {
            return Endpoint(method: .get,
                            path: userVatomPath + "/inventory/hash")
        }

        /// Builds the generic endpoint to get the current user's inventory.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getInventory<T>(parentID: String, page: Int = 0, limit: Int = 0) -> Endpoint<T> {
            return Endpoint(method: .post,
                            path: userVatomPath + "/inventory",
                            parameters: [
                                "parent_id": parentID,
                                "page": page,
                                "limit": limit
                ]
            )
        }

        /// Builds a generic endpoint to get a vatom payload by its unique identifier.
        ///
        /// Exlcudes Faces & Actions.
        ///
        /// - Parameter id: Unique identifier of the vatom.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getVatomPayload<T>(withID id: String) -> Endpoint<T> {
            return Endpoint(method: .get, path: "/v1/vatoms/\(id)")
        }

        /// Builds a generic endpoint to get vAtoms by their unique identifiers.
        ///
        /// - Parameter ids: Array of unique identifiers.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getVatoms<T>(withIDs ids: [String]) -> Endpoint<T> {
            assert(ids.count <= 100, "This call can retrive a maximum of 100 vatoms.")
            return Endpoint(method: .post,
                            path: userVatomPath + "/get",
                            parameters: ["ids": ids]
            )
        }

        /// Builds a generic endpoint to update a vAtom.
        ///
        /// - Parameter payload: Raw payload.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func updateVatom<T>(payload: [String: Any]) -> Endpoint<T> {
            return Endpoint(method: .patch,
                            path: "/v1/vatoms",
                            parameters: payload)
        }

        /// Builds a generic endpoint to search for vAtoms.
        ///
        /// - Parameter payload: Raw request payload.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func discover<T>(_ payload: [String: Any]) -> Endpoint<T> {

            return Endpoint(method: .post,
                            path: "/v1/vatom/discover",
                            parameters: payload)
        }

        /// Builds a generic endpoint to geo search for vAtoms (i.e. search for dropped vAtoms).
        ///
        /// Use this endpoint to fetch a collection of vAtoms.
        ///
        /// - Parameters:
        ///   - bottomLeftLat: Bottom left latitude coordinate.
        ///   - bottomLeftLon: Bottom left longitude coordinate.
        ///   - topRightLat: Top right latitude coordinate.
        ///   - topRightLon: Top right longitude coordinte.
        ///   - filter: The vAtom filter option to apply.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func geoDiscover<T>(bottomLeftLat: Double,
                                   bottomLeftLon: Double,
                                   topRightLat: Double,
                                   topRightLon: Double,
                                   filter: String) -> Endpoint<T> {

            // create the payload
            let payload: [String: Any] =
                [
                    "bottom_left":
                        [
                            "lat": bottomLeftLat,
                            "lon": bottomLeftLon
                    ],
                    "top_right":
                        [
                            "lat": topRightLat,
                            "lon": topRightLon
                    ],
                    "filter": filter
            ]

            // create the endpoint
            return Endpoint(method: .post,
                            path: "/v1/vatom/geodiscover",
                            parameters: payload)

        }

        /// Builds the endpoint to geo search for vAtom groups (i.e. search for clusters of dropped vAtoms).
        ///
        /// Use this endpoint to fetch an collection of groups/annotation indicating the count
        /// of vAtoms at a particular location.
        ///
        /// - Parameters:
        ///   - bottomLeftLat: Bottom left latitude coordinate.
        ///   - bottomLeftLon: Bottom left longitude coordinate.
        ///   - topRightLat: Top right latitude coordinate.
        ///   - topRightLon: Top right longitude coordinte.
        ///   - precision: The grouping precision applied when computing the groups.
        ///   - filter: The vAtom filter option to apply.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func geoDiscoverGroups<T>(bottomLeftLat: Double,
                                         bottomLeftLon: Double,
                                         topRightLat: Double,
                                         topRightLon: Double,
                                         precision: Int,
                                         filter: String) -> Endpoint<T> {

            assert(1...12 ~= precision, "You must specify a value in the open range [1...12].")

            // create the payload
            let payload: [String: Any] =
                [
                    "bottom_left":
                        [
                            "lat": bottomLeftLat,
                            "lon": bottomLeftLon
                    ],
                    "top_right":
                        [
                            "lat": topRightLat,
                            "lon": topRightLon
                    ],
                    "precision": precision,
                    "filter": filter
            ]

            // create the endpoint
            return Endpoint(method: .post,
                            path: "/v1/vatom/geodiscovergroups",
                            parameters: payload)

        }

        // MARK: Perform Actions

        /// Builds the endpoint to perform and action on a vAtom.
        ///
        /// - Parameters:
        ///   - name: Action name.
        ///   - payload: Raw payload for the action.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func perform<T>(name: String, payload: [String: Any]) -> Endpoint<T> {
            return Endpoint(method: .post,
                            path: actionPath + "/\(name)", parameters: payload)
        }

        // MARK: Fetch Actions

        /// Builds the endpoint for fetching the actions configured for a template ID.
        ///
        /// - Parameter id: Uniquie identifier of the template.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getActions<T>(forTemplateID id: String) -> Endpoint<T> {
            return Endpoint(method: .get,
                            path: userActionsPath + "/\(id)")
        }

        // MARK: User Activity

        /// Builds the endpoint for fetching the threads involving the current user.
        ///
        /// - Parameters:
        ///   - cursor: Filters out all threads more recent than the cursor (useful for paging).
        ///             If omitted or set as zero, the most recent threads are returned.
        ///   - count: Defines the number of messages to return (after the cursor).
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getThreads<T>(cursor: String, count: Int) -> Endpoint<T> {

            let payload: [String: Any] = [
                "cursor": cursor,
                "count": count
            ]

            return Endpoint(method: .post,
                            path: userActivityPath + "/mythreads",
                            parameters: payload)
        }

        /// Builds the endpoint for fetching the message for a specified thread involving the current user.
        ///
        /// - Parameters:
        ///   - id: Unique identifier of the thread (a.k.a thread `name`).
        ///   - cursor: Filters out all message more recent than the cursor (useful for paging).
        ///             If omitted or set as zero, the most recent threads are returned.
        ///   - count: Defines the number of messages to return (after the cursor).
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getMessages<T>(forThreadId threadId: String, cursor: String, count: Int) -> Endpoint<T> {

                let payload: [String: Any] = [
                    "name": threadId,
                    "cursor": cursor,
                    "count": count
                ]

                return Endpoint(method: .post,
                                path: userActivityPath + "/mythreadmessages",
                                parameters: payload)

        }

    }

}
