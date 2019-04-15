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

// swiftlint:disable file_length

/// Consolidates all BLOCKv API endpoints.
///
/// Endpoints are namespaced to furture proof.
///
/// Endpoints closely match their server counterparts where possible.
///
/// The goal is to abstract endpoint specific details. The networking client should
/// not need to taylor requests for the specific of an endpoint.
enum API { }

extension API {

    /*
     Notes:
     All Session, Current User, and Public User endpoints are wrapped in a container object. This is modelled as
     BaseModel.
     */

    // MARK: -

    /// Consolidates all session related endpoints.
    enum Session {

        // MARK: Register

        private static let registerPath = "/v1/users"

        /// Builds the endpoint for new user registration.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func register(tokens: [RegisterTokenParams], userInfo: UserInfo? = nil) ->
            Endpoint<BaseModel<AuthModel>> {

            precondition(!tokens.isEmpty, "One or more tokens must be supplied for this endpoint.")

            // dictionary of user information
            var params = [String: Any]()
            if let userInfo = userInfo {
                params = userInfo.toDictionary()
            }

            // create an array of tokens in their dictionary representation
            let tokens = tokens.map { $0.toDictionary() }
            params["user_tokens"] = tokens

            return Endpoint(method: .post,
                            path: registerPath,
                            parameters: params)

        }

        // MARK: Login

        private static let loginPath = "/v1/user/login"

        /// Builds the endpoint for user login.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func login(tokenParams: LoginTokenParams) -> Endpoint<BaseModel<AuthModel>> {
            return Endpoint(method: .post,
                            path: loginPath,
                            parameters: tokenParams.toDictionary())
        }

    }

    // MARK: -

    /// Consolidates all current user endpoints.
    enum CurrentUser {

        private static let currentUserPath = "/v1/user"

        /// Builds the endpoint to get the current user's properties.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func get() -> Endpoint<BaseModel<UserModel>> {
            return Endpoint(path: currentUserPath)
        }

        /// Builds the endpoint to get the current user's tokens.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getTokens() -> Endpoint<BaseModel<[FullTokenModel]>> {
            return Endpoint(path: currentUserPath + "/tokens")
        }

        /// Builds the endpoint to log out the current user.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func logOut() -> Endpoint<BaseModel<GeneralModel>> {
            return Endpoint(method: .post, path: currentUserPath + "/logout")
        }

        /// Builds the endpoint to update current user's information.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func update(userInfo: UserInfo) -> Endpoint<BaseModel<UserModel>> {
            return Endpoint(method: .patch,
                            path: currentUserPath,
                            parameters: userInfo.toSafeDictionary()
            )
        }

        /// Builds the endpoint to verify a token with an OTP code.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func verifyToken(_ token: UserToken, code: String) -> Endpoint<BaseModel<UserToken>> {
            return Endpoint(method: .post,
                            path: currentUserPath + "/verify_token",
                            parameters: [
                                "token": token.value,
                                "token_type": token.type.rawValue,
                                "verify_code": code
                ]
            )
        }

        /// Builds the endpoint to reset a user token.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func resetToken(_ token: UserToken) -> Endpoint<BaseModel<UserToken>> {
            return Endpoint(method: .post,
                            path: currentUserPath + "/reset_token",
                            parameters: token.toDictionary()
            )
        }

        /// Builds the endpoint to send a verification request for a specific token.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func resetTokenVerification(forToken token: UserToken) -> Endpoint<BaseModel<UserToken>> {
            return Endpoint(method: .post,
                            path: currentUserPath + "/reset_token_verification",
                            parameters: token.toDictionary()
            )
        }

        /// Builds the endpoint to add a token to the current user.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func addToken(_ token: UserToken, isPrimary: Bool) -> Endpoint<BaseModel<FullTokenModel>> {
            return Endpoint(method: .post,
                            path: currentUserPath + "/tokens",
                            parameters: [
                                "token": token.value,
                                "token_type": token.type.rawValue,
                                "is_primary": isPrimary
                ]
            )
        }

        /// Builds the endpoint to delete a token.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func deleteToken(id: String) -> Endpoint<BaseModel<GeneralModel>> {
            return Endpoint(method: .delete,
                            path: currentUserPath + "/tokens/\(id)")
        }

        /// Builds the endpoint to set a default token.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func setDefaultToken(id: String) -> Endpoint<BaseModel<GeneralModel>> {
            return Endpoint(method: .put,
                            path: currentUserPath + "/tokens/\(id)/default")
        }

        // MARK: Avatar

        /// Builds the endpoint for the user's avatar.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func uploadAvatar(_ imageData: Data) -> UploadEndpoint<BaseModel<GeneralModel>> {

            let bodyPart = MultiformBodyPart(data: imageData,
                                             name: "avatar",
                                             fileName: "avatar.png",
                                             mimeType: "image/png")
            return UploadEndpoint(path: "/v1/user/avatar",
                                  bodyPart: bodyPart)

        }

        // MARK: Messaging

        /// Builds the endpoint to allow the current user to send a message to a user token.
        ///
        /// - Parameters:
        ///   - message: Content of the message.
        ///   - userID: Unique identifier of the recipient user.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func sendMessage(_ message: String, toUserId userId: String) -> Endpoint<BaseModel<GeneralModel>> {
            return Endpoint(method: .post,
                            path: currentUserPath + "/message",
                            parameters: [
                                "message": message,
                                "id": userId])
        }

        // MARK: Redemption

        /*
         /// Endpoint to fetch redeemables.
         public static func getRedeemables() -> Endpoint<Void> {
         return Endpoint(path: currentUserPath + "/redeemables")
         }
         */

        // MARK: - DEBUG

        /// DO NOT EXPOSE. ONLY USE FOR TESTING.
        ///
        /// Builds the endpoint to allow the current user to be deleted.
        static func deleteCurrentUser() -> Endpoint<BaseModel<GeneralModel>> {
            return Endpoint(method: .delete, path: "/v1/user")
        }

    }

    // MARK: -

    /// Consolidates all public user endpoints.
    enum PublicUser {

        /// Builds the endpoint to get a public user's details.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func get(id: String) -> Endpoint<BaseModel<PublicUserModel>> {
            return Endpoint(path: "/v1/users/\(id)")
        }

    }

    // MARK: -

    /// Consolidates all user vatom endpoints.
    enum Vatom {

        /// Builds an endpoint to get the current user's inventory.
        ///
        /// The inventory call is essentially an optimized discover call. The server-pattern is from the child's
        /// perspetive. That is, we specify the id of the parent who's children are to be retunred.
        ///
        /// - Returns: Constructed endpoint specialized to parse out a `UnpackedModel`.
        static func getInventory(parentID: String,
                                 page: Int = 0,
                                 limit: Int = 0) -> Endpoint<BaseModel<UnpackedModel>> {
            return API.Generic.getInventory(parentID: parentID, page: page, limit: limit)

        }

        /// Builds an endpoint to get a vAtom by its unique identifier.
        ///
        /// - Parameter ids: Unique identifier of the vatom.
        /// - Returns: Constructed endpoint specialized to parse out a `UnpackedModel`.
        static func getVatoms(withIDs ids: [String]) -> Endpoint<BaseModel<UnpackedModel>> {
            return API.Generic.getVatoms(withIDs: ids)
        }

        /// Builds the endpoint to trash a vAtom specified by its id.
        ///
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func trashVatom(_ id: String) -> Endpoint<BaseModel<GeneralModel>> {
            return Endpoint(method: .post,
                            path: "/v1/user/vatom/trash",
                            parameters: ["this.id": id])

        }

        /// Builds an endpoint to update a vAtom.
        ///
        /// - Parameter payload: Raw payload.
        /// - Returns: Constructed endpoint specialized to parse out a `VatomUpdateModel`.
        static func updateVatom(payload: [String: Any]) -> Endpoint<BaseModel<VatomUpdateModel>> {
            return API.Generic.updateVatom(payload: payload)
        }

        /// Builds an endpoint to search for vAtoms.
        ///
        /// - Parameter payload: Raw request payload.
        /// - Returns: Constructed endpoint specialized to parse out a `UnpackedModel`.
        static func discover(_ payload: [String: Any]) -> Endpoint<BaseModel<UnpackedModel>> {
            return API.Generic.discover(payload)
        }

        /// Builds an endpoint to geo search for vAtoms (i.e. search for dropped vAtoms).
        ///
        /// Use this endpoint to fetch a collection of vAtoms.
        ///
        /// - Parameters:
        ///   - bottomLeftLat: Bottom left latitude coordinate.
        ///   - bottomLeftLon: Bottom left longitude coordinate.
        ///   - topRightLat: Top right latitude coordinate.
        ///   - topRightLon: Top right longitude coordinte.
        ///   - filter: The vAtom filter option to apply.
        /// - Returns: Constructed endpoint specialized to parse out a `UnpackedModel`.
        static func geoDiscover(bottomLeftLat: Double,
                                bottomLeftLon: Double,
                                topRightLat: Double,
                                topRightLon: Double,
                                filter: String) -> Endpoint<BaseModel<UnpackedModel>> {

            return API.Generic.geoDiscover(bottomLeftLat: bottomLeftLat,
                        bottomLeftLon: bottomLeftLon,
                        topRightLat: topRightLat,
                        topRightLon: topRightLon,
                        filter: filter)
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
        static func geoDiscoverGroups(bottomLeftLat: Double,
                                      bottomLeftLon: Double,
                                      topRightLat: Double,
                                      topRightLon: Double,
                                      precision: Int,
                                      filter: String) -> Endpoint<BaseModel<GeoModel>> {

            return API.Generic.geoDiscoverGroups(bottomLeftLat: bottomLeftLat,
                                                     bottomLeftLon: bottomLeftLon,
                                                     topRightLat: topRightLat,
                                                     topRightLon: topRightLon,
                                                     precision: precision,
                                                     filter: filter)

        }

    }

    // MARK: -

    /// Consolidates all action endpoints.
    enum VatomAction {

        /*
         Each action's reactor returns it's own json payload. This does not need to be mapped as yet.
         */

        /// Builds the endpoint to perform and action on a vAtom.
        ///
        /// - Parameters:
        ///   - name: Action name.
        ///   - payload: Raw payload for the action.
        /// - Returns: Constructed endpoint generic over `Void` that may be passed to a request.
        static func custom(name: String, payload: [String: Any]) -> Endpoint<Void> {
            return API.Generic.perform(name: name, payload: payload)
        }

    }

    // MARK: -

    /// Consolidates all the user actions.
    enum UserActions {

        /// Builds the endpoint for fetching the actions configured for a template ID.
        ///
        /// - Parameter id: Uniquie identifier of the template.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getActions(forTemplateID id: String) -> Endpoint<BaseModel<[ActionModel]>> {
            return API.Generic.getActions(forTemplateID: id)
        }

    }

    // MARK: -

    /// Consolidtes all the user activity endpoints.
    enum UserActivity {

        /// Builds the endpoint for fetching the threads involving the current user.
        ///
        /// - Parameters:
        ///   - cursor: Filters out all threads more recent than the cursor (useful for paging).
        ///             If omitted or set as zero, the most recent threads are returned.
        ///   - count: Defines the number of messages to return (after the cursor).
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getThreads(cursor: String, count: Int) -> Endpoint<BaseModel<ThreadListModel>> {
            return API.Generic.getThreads(cursor: cursor, count: count)
        }

        /// Builds the endpoint for fetching the message for a specified thread involving the current user.
        ///
        /// - Parameters:
        ///   - id: Unique identifier of the thread (a.k.a thread `name`).
        ///   - cursor: Filters out all message more recent than the cursor (useful for paging).
        ///             If omitted or set as zero, the most recent threads are returned.
        ///   - count: Defines the number of messages to return (after the cursor).
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getMessages(forThreadId threadId: String, cursor: String, count: Int) ->
            Endpoint<BaseModel<MessageListModel>> {
                return API.Generic.getMessages(forThreadId: threadId, cursor: cursor, count: count)
        }

    }

}

extension API {

    enum Generic {

        private static let userVatomPath    = "/v1/user/vatom"
        private static let userActionsPath  = "/v1/user/actions"
        private static let actionPath       = "/v1/user/vatom/action"
        private static let userActivityPath = "/v1/activity"

        // MARK: Vatoms

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

        /// Builds a generic endpoint to get a vAtom by its unique identifier.
        ///
        /// - Parameter ids: Unique identifier of the vatom.
        /// - Returns: Constructed endpoint generic over response model that may be passed to a request.
        static func getVatoms<T>(withIDs ids: [String]) -> Endpoint<T> {
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

        // MARK: - Perform Actions

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

        // MARK: - User Activity

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
