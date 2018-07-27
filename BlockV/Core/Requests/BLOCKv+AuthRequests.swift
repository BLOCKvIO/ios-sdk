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

/// This extension groups together all BLOCKv auth requests.
extension BLOCKv {

    // MARK: - Register

    /// Registers a user on the BLOCKv platform. Accepts a user token (phone or email).
    ///
    /// - Parameters:
    ///   - token: A user token value, i.e. phone number or email.
    ///   - type: The type of the token `phone` or `email`.
    ///   - userInfo: A simple struct that holds properties of the user, e.g. first name.
    ///               Only the properties to be registered should be set.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func register(withUserToken token: String,
                                type: UserTokenType,
                                userInfo: UserInfo? = nil,
                                completion: @escaping (UserModel?, BVError?) -> Void) {
        let registerToken = UserToken(value: token, type: type)
        self.register(tokens: [registerToken], userInfo: userInfo, completion: completion)
    }

    /// Registers a user on the BLOCKv platform. Accepts an OAuth token.
    ///
    /// - Parameters:
    ///   - oauthToken: An OAuth token from a supported OAuth provider, e.g. Facebook.
    ///   - userInfo: A simple struct that holds properties of the user, e.g. first name.
    ///               Only the properties to be registered should be set.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func register(withOAuthToken oauthToken: OAuthTokenRegisterParams,
                                userInfo: UserInfo? = nil,
                                completion: @escaping (UserModel?, BVError?) -> Void) {
        self.register(tokens: [oauthToken], userInfo: userInfo, completion: completion)
    }

    /// Registers a user on the BLOCKv platform.
    ///
    /// This call allows for multiple tokens (e.g. phone, email, or OAuth) to be associated
    /// with the user's account.
    ///
    /// Note: After registration the user is considered to be logged in and is
    /// authorized to perform requests.
    public static func register(tokens: [RegisterTokenParams],
                                userInfo: UserInfo? = nil,
                                completion: @escaping (UserModel?, BVError?) -> Void) {

        let endpoint = API.Session.register(tokens: tokens, userInfo: userInfo)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard let authModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                // persist credentials
                CredentialStore.saveRefreshToken(authModel.refreshToken)
                CredentialStore.saveAssetProviders(authModel.assetProviders)

                completion(authModel.user, nil)
            }

        }

    }

    // MARK: Login

    /// Logs a user into the BLOCKv platform. Accepts a user token (phone or email).
    ///
    /// - Parameters:
    ///   - token: A user token value, i.e. phone number or email.
    ///   - type: The type of the token `phone` or `email`.
    ///   - password: The user's password.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func login(withUserToken token: String,
                             type: UserTokenType,
                             password: String,
                             completion: @escaping (UserModel?, BVError?) -> Void) {
        let params = UserTokenLoginParams(value: token, type: type, password: password)
        self.login(tokenParams: params, completion: completion)
    }

    /// Logs a user into the BLOCKv platform. Accepts an OAuth token.
    ///
    /// - Parameters:
    ///   - oauthToken: The OAuth token issued by the OAuth provider.
    ///   - provider: The OAuth provider, e.g. Facebook.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func login(withOAuthToken oauthToken: String,
                             provider: String,
                             completion: @escaping (UserModel?, BVError?) -> Void) {
        let params = OAuthTokenLoginParams(provider: provider, oauthToken: oauthToken)
        self.login(tokenParams: params, completion: completion)
    }

    /// Logs a user into the BLOCKv platform. Accepts a guest ID.
    ///
    /// - Parameters:
    ///   - id: User identifier generated by the BLOCKv platform.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func login(withGuestID id: String,
                             completion: @escaping (UserModel?, BVError?) -> Void) {
        let params = GuestIdLoginParams(id: id)
        self.login(tokenParams: params, completion: completion)
    }

    /// Login using token params
    fileprivate static func login(tokenParams: LoginTokenParams,
                                  completion: @escaping (UserModel?, BVError?) -> Void) {

        let endpoint = API.Session.login(tokenParams: tokenParams)

        self.client.request(endpoint) { (baseModel, error) in

            // extract model, ensure no error
            guard let authModel = baseModel?.payload, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {

                // persist credentials
                CredentialStore.saveRefreshToken(authModel.refreshToken)
                CredentialStore.saveAssetProviders(authModel.assetProviders)

                // completion
                completion(authModel.user, nil)
            }

        }

    }

    // MARK: - Logout

    /// Log out the current user.
    ///
    /// The current user will no longer be authorized to perform user scoped requests on the
    /// BLOCKv platform.
    ///
    /// - Parameter completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func logout(completion: @escaping (BVError?) -> Void) {

        let endpoint = API.CurrentUser.logOut()

        self.client.request(endpoint) { (baseModel, error) in

            // reset
            DispatchQueue.main.async {
                reset()
            }

            // extract model, ensure no error
            guard baseModel?.payload != nil, error == nil else {
                DispatchQueue.main.async {
                    completion(error!)
                }
                return
            }

            // model is available
            DispatchQueue.main.async {
                completion(nil)
            }

        }

    }

}
