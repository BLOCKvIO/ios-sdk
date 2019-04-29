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
import SafariServices

//TODO: Update for iOS 12 ASWebAuthenticationSession

public final class AuthorizationServer {

    // MARK: - Properties

    // viewer config
    let clientID: String // viewer app-id
    let domain: String // login web app domain
    let scope: String // requested scope
    let redirectURI: String // publisher registered redirect url

    var receivedCode: String?
    var receivedState: String?

    private var authSession: SFAuthenticationSession?
    private var savedState: String?

    // MARK: - Initialization

    public init(clientID: String, domain: String, scope: String, redirectURI: String) {
        self.clientID = clientID
        self.domain = domain
        self.scope = scope
        self.redirectURI = redirectURI
    }

    // MARK: - Methods

    /// Begins delegated authorization.
    public func authorize(handler: @escaping (Bool) -> Void) {

        savedState = generateState(withLength: 20)

        var urlComp = URLComponents(string: domain)!

        urlComp.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "state", value: savedState!),
            URLQueryItem(name: "scope", value: scope)
        ]

        //TODO: Should the `callbackURLScheme` include more than the redirectURL, e.g. bundle identifier?
        // init an auth session
        authSession = SFAuthenticationSession(url: urlComp.url!,
                                              callbackURLScheme: redirectURI,
                                              completionHandler: { (url, error) in
            guard error == nil else {
                return handler(false)
            }

            handler(url != nil && self.parseAuthorizeRedirectURL(url!))

        })
        // start the authentication session
        authSession?.start()

    }

    /// Parse authorised redirect URL.
    ///
    /// `code` and `state` instance properties are updated.
    ///
    /// - Parameter url: Parses out the information in the redirect URL.
    /// - Returns: Boolean value indicating the outcome of parsing the authorize redirect url.
    func parseAuthorizeRedirectURL(_ url: URL) -> Bool {

        // decompose into components
        guard let urlComp = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            authSession?.cancel()
            return false
        }
        // find query items
        guard let items = urlComp.queryItems else {
            authSession?.cancel()
            return false
        }
        // extract code and state
        receivedCode = items.first(where: { $0.name == "code" })?.value
        receivedState = items.first(where: { $0.name == "state" })?.value

        // dismiss
        authSession?.cancel()
        return receivedCode != nil && receivedState != nil

    }

    /// Exchanges authorization code for tokens.
    ///
    /// - Parameter completion: Completion handler that is called once the request has been processed.
    func getToken(completion: @escaping (Result<OAuthTokenExchangeModel, BVError>) -> Void) {
        // sanity checks
        guard let code = receivedCode else {
            let error = BVError.session(reason: .invalidAuthoriationCode)
            completion(.failure(error))
            return
        }
        // security: scheck state match
        guard savedState == receivedState else {
            let error = BVError.session(reason: .nonMatchingStates)
            completion(.failure(error))
            return
        }

        // build token exchange endpoint
        let endpoint = API.Session.tokenExchange(grantType: "authorization_code",
                                                 clientID: self.clientID,
                                                 code: code,
                                                 redirectURI: redirectURI)

        // perform request
        BLOCKv.client.request(endpoint) { result in
            switch result {
            case .success(let model):
                //FIXME: Temporary converstion between temporary token model
                let oauthTokenExchangeModel = OAuthTokenExchangeModel(accessToken: model.payload.accessToken.token,
                                                                      refreshToken: model.payload.refreshToken.token,
                                                                      tokenType: model.payload.accessToken.tokenType,
                                                                      expriesIn: nil,
                                                                      scope: nil)

                completion(.success(oauthTokenExchangeModel))

            case .failure(let error):
                completion(.failure(error))
            }
        }

    }

    // MARK: Helpers

    private func generateState(withLength len: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let length = UInt32(letters.count)

        var randomString = ""
        for _ in 0..<len {
            let rand = arc4random_uniform(length)
            let idx = letters.index(letters.startIndex, offsetBy: Int(rand))
            let letter = letters[idx]
            randomString += String(letter)
        }
        return randomString
    }

}
