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

/// This extension groups together all BLOCKv user requests.
extension BLOCKv {

    // MARK: - User

    /// Fetches the current user's profile information from the BLOCKv platform.
    ///
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func getCurrentUser(completion: @escaping (UserModel?, BVError?) -> Void) {

        let endpoint = API.CurrentUser.get()

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard let userModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(userModel, nil)
            }

        }

    }

    /// Updates the current user's profile on the BLOCKv platform.
    ///
    /// - Parameters:
    ///   - userInfo: A simple struct that holds the properties of the user, e.g. their first name.
    ///               Only the properties to be updated should be set.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func updateCurrentUser(_ userInfo: UserInfo,
                                         completion: @escaping (UserModel?, BVError?) -> Void) {

        let endpoint = API.CurrentUser.update(userInfo: userInfo)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard let userModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(userModel, nil)
            }

        }

    }

    /// Uploads an avatar image to the BlockV platform.
    ///
    /// It is recommended that scalling and cropping be done before calling this method.
    ///
    /// - Parameters:
    ///   - image: The image to upload.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func uploadAvatar(_ image: UIImage,
                                    progressCompletion: @escaping (_ percent: Float) -> Void,
                                    completion: @escaping (BVError?) -> Void) {

        //TODO: Perhaps this method should require Data instead of UIImage?

        // create image data
        guard let imageData = UIImagePNGRepresentation(image) else {
            let error = BVError.custom(reason: "\nBV SDK >>> Error: Conversion to png respresetation returned nil.")
            completion(error)
            return
        }

        // build endpoint
        let endpoint = API.CurrentUser.uploadAvatar(imageData)

        self.client.upload(endpoint, progressCompletion: progressCompletion) { (baseModel, error) in

            // extract model, ensure no error
            guard baseModel?.payload != nil, error == nil else {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(nil)
            }

        }

    }

    // MARK: - Token Verification

    /// Verifies ownership of a token by submitting the verification code to the BLOCKv platform.
    ///
    /// - Parameters:
    ///   - token: A user token value, i.e. phone number or email.
    ///   - type: The type of the token `phone` or `email`.
    ///   - code: The verification code send to the user's token (phone or email).
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func verifyUserToken(_ token: String,
                                       type: UserTokenType,
                                       code: String,
                                       completion: @escaping (UserToken?, BVError?) -> Void) {

        let userToken = UserToken(value: token, type: type)
        let endpoint = API.CurrentUser.verifyToken(userToken, code: code)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard let userTokenModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(userTokenModel, nil)
            }

        }

    }

    /// Resets the verification process. Sends a verification item to the user's token (phone or email).
    ///
    /// This verification item should be used to verifiy the user's ownership of the token (phone or email).
    /// Note: the type of verification is dependent on the configuration of the app id on the developer portal.
    ///
    /// - Parameters:
    ///   - token: A user token value, i.e. phone number or email.
    ///   - type: The type of the token `phone` or `email`.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func resetVerification(forUserToken token: String,
                                         type: UserTokenType,
                                         completion: @escaping (UserToken?, BVError?) -> Void) {

        let userToken = UserToken(value: token, type: type)
        let endpoint = API.CurrentUser.resetTokenVerification(forToken: userToken)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, handle error
            guard let userTokenModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(userTokenModel, nil)
            }

        }

    }

    /// Resets a user token. This will remove the user's password and trigger
    /// a One-Time-Pin (OTP) to be sent to the supplied user token.
    ///
    /// Note: This OTP may be used in place of a password to login.
    ///
    /// - Parameters:
    ///   - token: A user token value, i.e. phone number or email.
    ///   - type: The type of the token `phone` or `email`.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func resetToken(_ token: String,
                                  type: UserTokenType,
                                  completion: @escaping (UserToken?, BVError?) -> Void) {

        let userToken = UserToken(value: token, type: type)
        let endpoint = API.CurrentUser.resetToken(userToken)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard let userTokenModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(userTokenModel, nil)
            }

        }

    }

    // MARK: Token Management

    /// Adds a user token to the current user.
    ///
    /// - Parameters:
    ///   - token: The user token to be linked to the current user.
    ///   - isDefault: Boolean controlling whether the token is the primary token on this account.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func addCurrentUserToken(token: UserToken,
                                           isPrimary: Bool = false,
                                           completion: @escaping (FullTokenModel?, BVError?) -> Void) {

        let endpoint = API.CurrentUser.addToken(token, isPrimary: isPrimary)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, handle error
            guard let fullToken = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(fullToken, nil)
            }

        }

    }

    /// Fetches the current user's token description from the BLOCKv platform.
    ///
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func getCurrentUserTokens(completion: @escaping ([FullTokenModel]?, BVError?) -> Void) {

        let endpoint = API.CurrentUser.getTokens()

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, handle error
            guard let fullTokens = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(fullTokens, nil)
            }

        }

    }

    /// Removes the token from the current user's token list on the BLOCKv platform.
    ///
    /// Note: Primary tokens may not be deleted.
    ///
    /// - Parameters:
    ///   - tokenId: Unique identifier of the token to be deleted.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func deleteCurrentUserToken(_ tokenId: String,
                                              completion: @escaping (BVError?) -> Void) {

        let endpoint = API.CurrentUser.deleteToken(id: tokenId)

        self.client.request(endpoint) { (baseModel, error) in

            guard baseModel?.payload != nil, error == nil else {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }

            // call was successful
            DispatchQueue.main.async {
                completion(nil)
            }

        }

    }

    /// Updates the specified token to be the current user's default token on the BLOCKv platform.
    ///
    /// Backend description:
    /// Boolean to indicate if this token is the primary token. The primary token is used when no other
    /// token is explicitly selected, for example to send messages. This will automatically set the
    /// is_primary flag of an existing token to false , because only one token can be the primary token.
    ///
    /// - Parameters:
    ///   - tokenId: Unique identifer of the token.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func setCurrentUserDefaultToken(_ tokenId: String,
                                                  completion: @escaping (BVError?) -> Void) {

        let endpoint = API.CurrentUser.setDefaultToken(id: tokenId)

        self.client.request(endpoint) { (baseModel, error) in

            //
            guard baseModel?.payload != nil, error == nil else {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }

            // call was succesful
            DispatchQueue.main.async {
                completion(nil)
            }

        }

    }

    // MARK: - Public User

    /// Fetches the publicly available attributes of any user given their user id.
    ///
    /// Since users are given control over which attributes they make public, you should make
    /// provision for receiving all, some, or none of their public attributes.
    ///
    /// - Parameters:
    ///   - userId: Unique identifier of the user.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func getPublicUser(withID userId: String,
                                     completion: @escaping (PublicUserModel?, BVError?) -> Void) {

        let endpoint = API.PublicUser.get(id: userId)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard let userModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(userModel, nil)
            }

        }

    }
    
    /// DO NOT EXPOSE. ONLY USE FOR TESTING.
    ///
    /// DELETES THE CURRENT USER.
    internal static func deleteCurrentUser(completion: @escaping (Error?) -> Void) {
        
        let endpoint = API.CurrentUser.deleteCurrentUser()
        
        self.client.request(endpoint) { (baseModel, error) in
            
            guard baseModel?.payload != nil, error == nil else {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(nil)
            }
            
        }
        
    }

}
