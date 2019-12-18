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

/// This extension groups together all BLOCKv auth requests.
extension BLOCKv {

    // MARK: - Register

    /// Begins the OAuth authentication flow.
    ///
    /// - Parameter scope: Scope value.
    /// - Parameter redirectURI: Custom redirect URI.
    /// - Parameter completion: Completion handler to call once the OAuth process has completed or cancelled.
    public static func oauth(scope: String,
                             redirectURI: String,
                             completion: @escaping (Result<(AuthorizationServer.Flow, UserModel), BVError>) -> Void) {

        // ensure host app has set an app id
        let warning = """
            Please call 'BLOCKv.configure(appID:)' with your issued app ID before making network
            requests.
            """
        precondition(BLOCKv.appID != nil, warning)

        // extract config variables
        let appID = BLOCKv.appID!
        let webAppDomain = BLOCKv.environment!.oauthWebApp

        let authServer = AuthorizationServer(clientID: appID, domain: webAppDomain, scope: scope,
                                             redirectURI: redirectURI)

        // start delegated authorization
        authServer.authorize { result in

            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return

            case .success(let flowModel):

                // exchange code for tokens
                authServer.getToken { result in

                    switch result {
                    case .success(let tokens):
                        /*
                         At this point, accces and refresh tokens have been injected into the oauthhandler by the client
                         response inspector.
                         */

                        // build endpoint
                        let endpoint = API.Session.getAssetProviders()
                        // perform api call
                        BLOCKv.client.request(endpoint) { result in
                            switch result {
                            case .success(let model):

                                // pull back to main queue
                                DispatchQueue.main.async {

                                    let refreshToken = BVToken(token: tokens.refreshToken, tokenType: tokens.tokenType)
                                    // persist refresh token and credential
                                    CredentialStore.saveRefreshToken(refreshToken)
                                    CredentialStore.saveAssetProviders(model.payload.assetProviders)

                                    // noifty on login process
                                    self.onLogin()

                                    // fetch current user
                                    self.getCurrentUser { result in
                                        do {
                                            let user = try result.get()
                                            DispatchQueue.main.async { completion(.success((flowModel, user))) }
                                        } catch {
                                            //swiftlint:disable:next force_cast
                                            DispatchQueue.main.async { completion( .failure(error as! BVError)) }
                                        }
                                    }

                                }

                            case .failure(let error):
                                DispatchQueue.main.async { completion(.failure(error)) }
                            }
                        }

                    case .failure(let error):
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }

                }

            }
        }
    }

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
                                completion: @escaping (Result<UserModel, BVError>) -> Void) {
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
                                completion: @escaping (Result<UserModel, BVError>) -> Void) {
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
                                completion: @escaping (Result<UserModel, BVError>) -> Void) {

        let endpoint = API.Session.register(tokens: tokens, userInfo: userInfo)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                DispatchQueue.main.async {
                    let authModel = baseModel.payload
                    // persist credentials
                    CredentialStore.saveRefreshToken(authModel.refreshToken)
                    CredentialStore.saveAssetProviders(authModel.assetProviders)
                    // noifty
                    self.onLogin()
                    completion(.success(authModel.user))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
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
                             completion: @escaping (Result<UserModel, BVError>) -> Void) {
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
                             completion: @escaping (Result<UserModel, BVError>) -> Void) {
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
                             completion: @escaping (Result<UserModel, BVError>) -> Void) {
        let params = GuestIdLoginParams(id: id)
        self.login(tokenParams: params, completion: completion)
    }

    /// Login using token params
    fileprivate static func login(tokenParams: LoginTokenParams,
                                  completion: @escaping (Result<UserModel, BVError>) -> Void) {

        let endpoint = API.Session.login(tokenParams: tokenParams)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                DispatchQueue.main.async {
                    let authModel = baseModel.payload
                    // persist credentials
                    CredentialStore.saveRefreshToken(authModel.refreshToken)
                    CredentialStore.saveAssetProviders(authModel.assetProviders)
                    // notify
                    self.onLogin()
                    // completion
                    completion(.success(authModel.user))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
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

        self.client.request(endpoint) { result in

            DispatchQueue.main.async {
                // reset sdk state
                reset()
                // give viewer opportunity to reset their state
                onLogout?()
            }

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

    /// Fetches information regarding app versioning and support.
    ///
    /// - Parameter result: Complettion handler that is called when the request is completed.
    public static func getSupportedVersion(result: @escaping (Result<AppUpdateModel, BVError>) -> Void) {

        let endpoint = API.Session.getSupportedVersion()
        // send request
        self.client.request(endpoint) { innerResult in

            switch innerResult {
            case .success(let model):
                // model is available
                DispatchQueue.main.async {
                    result(.success(model.payload))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    result(.failure(error))
                }
            }

        }

    }

    /// Updates the push notification settings for this device.
    ///
    /// - Parameters:
    ///   - fcmToken: Firebase cloud messaging token.
    ///   - platformID: Identifier of the current plaform. Defaults to "ios" - recommended.
    ///   - enabled: Flag indicating whether push notifications should be sent to this device. Defaults to `true`.
    ///   - completion: Completion handler that is called when the request is completed.
    public static func updatePushNotification(fcmToken: String,
                                              platformID: String,
                                              enabled: Bool,
                                              completion: @escaping ((Error?) -> Void)) {

        let endpoint = API.Session.updatePushNotification(fcmToken: fcmToken, platformID: platformID, enabled: enabled)
        // send request
        self.client.request(endpoint) { result in

            switch result {
            case .success:
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
