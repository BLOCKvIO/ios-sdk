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

/// Consolidates all BlockV API endpoints.
///
/// Endpoints are namespaced to furture proof.
///
/// Endpoints closely match their server counterparts where possible.
/// If appropriate, some endpoints may represent a single server endpoint.
///
/// The goal is to abstract endpoint specific details. The networking client should
/// not need to taylor requests for the specific of an endpoint.
enum API { }

extension API {
    
    /*
     All Session, Current User, and Public User endpoints are wrapped in a (unnecessary)
     container object. This is modelled here using a `BaseModel`.
     */
    
    // MARK: -
    
    /// Consolidates all session related endpoints.
    enum Session {
        
        // MARK: Register
        
        private static let registerPath = "/v1/users"
        
        /// Builds the endpoint for new user registration.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func register(tokens: [RegisterTokenParams], userInfo: UserInfo? = nil) -> Endpoint<BaseModel<AuthModel>> {
            
            precondition(!tokens.isEmpty, "One or more tokens must be supplied for this endpoint.")
            
            // dictionary of user information
            var params = [String : Any]()
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
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
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
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func get() -> Endpoint<BaseModel<UserModel>> {
            return Endpoint(path: currentUserPath)
        }
        
        /// Builds the endpoint to get the current user's tokens.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func getTokens() -> Endpoint<BaseModel<[FullTokenModel]>> {
            return Endpoint(path: currentUserPath + "/tokens")
        }
        
        /// Builds the endpoint to log out the current user.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func logOut() -> Endpoint<BaseModel<GeneralModel>> {
            return Endpoint(method: .post, path: currentUserPath + "/logout")
        }
        
        /// Builds the endpoint to update current user's information.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func update(userInfo: UserInfo) -> Endpoint<BaseModel<UserModel>> {
            return Endpoint(method: .patch,
                            path: currentUserPath,
                            parameters: userInfo.toSafeDictionary()
            )
        }
        
        /// Builds the endpoint to verify a token with an OTP code.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
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
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func resetToken(_ token: UserToken) -> Endpoint<BaseModel<UserToken>> {
            return Endpoint(method: .post,
                            path: currentUserPath + "/reset_token",
                            parameters: token.toDictionary()
            )
        }
        
        /// Builds the endpoint to send a verification request for a specific token.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func resetTokenVerification(forToken token: UserToken) -> Endpoint<BaseModel<UserToken>> {
            return Endpoint(method: .post,
                            path: currentUserPath + "/reset_token_verification",
                            parameters: token.toDictionary()
            )
        }
        
        /// Builds the endpoint to add a token to the current user.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        public static func addToken(_ token: UserToken, isPrimary: Bool) -> Endpoint<BaseModel<FullTokenModel>> {
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
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        public static func deleteToken(id: String) -> Endpoint<BaseModel<GeneralModel>> {
            return Endpoint(method: .delete,
                            path: currentUserPath + "/tokens/\(id)")
        }
        
        /// Builds the endpoint to set a default token.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        public static func setDefaultToken(id: String) -> Endpoint<BaseModel<GeneralModel>> {
            return Endpoint(method: .put,
                            path: currentUserPath + "/tokens/\(id)/default")
        }
        
        // MARK: Redemption
        
        /*
         /// Endpoint to fetch redeemables.
         public static func getRedeemables() -> Endpoint<Void> {
         return Endpoint(path: currentUserPath + "/redeemables")
         }
         */
        
        // MARK: Avatar
        
        /// Builds the endpoint for the user's avatar.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func uploadAvatar(_ imageData: Data) -> UploadEndpoint<BaseModel<GeneralModel>> {
            
            let bodyPart = MultiformBodyPart(data: imageData, name: "avatar", fileName: "avatar.png", mimeType: "image/png")
            return UploadEndpoint(path: "/v1/user/avatar",
                                  bodyPart: bodyPart)
            
        }
        
    }
    
    // MARK: -
    
    /// Consolidates all public user endpoints.
    enum PublicUser {
        
        /// Builds the endpoint to get a public user's details.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func get(id: String) -> Endpoint<BaseModel<PublicUserModel>> {
            return Endpoint(path: "/v1/users/\(id)")
        }
        
    }
    
    // MARK: -
    
    /// Consolidates all user vatom endpoints.
    enum UserVatom {
        
        private static let userVatomPath = "/v1/user/vatom"
        
        //TODO: Parameterise parameters.
        
        /// Builds the endpoint to get the current user's inventory.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func getInventory(parentID: String = "*",
                                 page: Int = 0,
                                 limit: Int = 0) -> Endpoint<BaseModel<GroupModel>> {
            return Endpoint(method: .post,
                            path: userVatomPath + "/inventory",
                            parameters: [
                                "parent_id": ".",
                                "page": page,
                                "limit": limit
                ]
            )
        }
        
        /// Builds the endpoint to get a vAtom by its unique identifier.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func getVatoms(withIDs ids: [String]) -> Endpoint<BaseModel<GroupModel>> {
            return Endpoint(method: .post,
                            path: userVatomPath + "/get",
                            parameters: ["ids": ids]
            )
        }
        
    }
    
    // MARK: -
    
    /// Consolidtaes all discover endpoints.
    enum VatomDiscover {
        
        /// Builds the endpoint to search for vAtoms.
        ///
        /// - Parameter payload: Raw request payload.
        /// - Returns: Endpoint generic over `GroupModel`.
        static func discover(_ payload: [String : Any]) -> Endpoint<BaseModel<GroupModel>> {
            
            return Endpoint(method: .post,
                            path: "/v1/vatom/discover",
                            parameters: payload)
        }
        
        /// Builds the endpoint to geo search for vAtoms (i.e. search for dropped vAtoms).
        ///
        /// Use this endpoint to fetch a collection of vAtoms.
        ///
        /// - Parameters:
        ///   - bottomLeftLat: Bottom left latitude coordinate.
        ///   - bottomLeftLon: Bottom left longitude coordinate.
        ///   - topRightLat: Top right latitude coordinate.
        ///   - topRightLon: Top right longitude coordinte.
        ///   - filter: The vAtom filter option to apply.
        /// - Returns: Endpoint generic over `GroupModel`.
        static func geoDiscover(bottomLeftLat: Double,
                                bottomLeftLon: Double,
                                topRightLat: Double,
                                topRightLon: Double,
                                filter: String) -> Endpoint<BaseModel<GroupModel>> {
            
            // create the payload
            let payload: [String : Any] =
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
        /// - Returns: Endpoint generic over `GeoGroupModel`.
        static func geoDiscoverGroups(bottomLeftLat: Double,
                                      bottomLeftLon: Double,
                                      topRightLat: Double,
                                      topRightLon: Double,
                                      precision: Int,
                                      filter: String) -> Endpoint<BaseModel<GeoModel>> {
            
            assert(1...12 ~= precision, "You must specify a value in the open range [1...12].")
            
            // create the payload
            let payload: [String : Any] =
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
        
    }
    
    // MARK: -
    
    /// Consolidates all action endpoints.
    enum VatomAction {
        
        private static let actionPath = "/v1/user/vatom/action"
        
        /*
         Each action's reactor returns it's own json payload. This does not need to be mapped as yet.
         */
        
        /// Builds the endpoint to perform and action on a vAtom.
        ///
        /// - Parameters:
        ///   - name: Action name.
        ///   - payload: Raw payload for the action.
        /// - Returns: Returns endpoint generic over Void, i.e. caller will receive raw data.
        static func custom(name: String, payload: [String : Any]) -> Endpoint<Void> {
            return Endpoint(method: .post,
                            path: actionPath + "/\(name)",
                parameters: payload)
        }
        
    }
    
    // MARK: -
    
    /// Consolidates all the user actions.
    enum UserActions {
        
        private static let userActionsPath = "/v1/user/actions"
        
        /// Builds the endpoint for fetching the actions configured for a template ID.
        ///
        /// - Parameter id: Uniquie identifier of the template.
        /// - Returns: Endpoint for fectching actions.
        static func getActions(forTemplateID id: String) -> Endpoint<BaseModel<[Action]>> {
            return Endpoint(method: .get,
                            path: userActionsPath + "/\(id)")
        }
        
    }
    
}
