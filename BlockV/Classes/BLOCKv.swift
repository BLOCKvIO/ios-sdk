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
import JWTDecode

// Beta 0.9
//TODO: Inpect the `expires_in` before a request is made. Refresh the access token if necessary.

/// Primary interface into the the BLOCKv SDK.
public final class BLOCKv {
    
    // MARK: - Enums
    
    /// Models the BLOCKv platform environments.
    ///
    /// Options:
    /// - production
    public enum BVEnvironment: String {
        case production = "https://api.blockv.io"
        case development = "https://apidev.blockv.net"
    }
    
    // MARK: - Properties
    
    /// The App ID to be passed to the BLOCKv platform.
    ///
    /// Must be set once by the host app.
    fileprivate static var appID: String? {
        // willSet is only called outside of the initialisation context, i.e.
        // setting the appID after its init will cause a fatal error.
        willSet {
            if appID != nil {
                assertionFailure("The App ID may be set only once.")
            }
        }
    }
    
    //TODO: Detect an environment switch, e.g. dev to prod, reset the client.
    
    /// The BLOCKv platform environment to use.
    ///
    /// Must be set by the host app.
    fileprivate static var environment: BVEnvironment? {
        willSet {
            if environment != nil { reset() }
        }
        didSet { printBV(info: "Environment updated: \(environment!)") }
    }
    
    /// Computes the configuration object needed to initialise the networking client.
    fileprivate static var clientConfiguration: Client.Configuration {
        get {
            // ensure host app has set an app id
            precondition(BLOCKv.appID != nil, "Please call 'BLOCKv.configure(appID:)' with your issued app ID before making network requests.")
            
            if environment == nil {
                self.environment = .production // default to production
            }
            
            // return the configuration (inexpensive object)
            return Client.Configuration(baseURLString: BLOCKv.environment!.rawValue,
                                        appID: BLOCKv.appID!,
                                        refreshToken: CredentialStore.refreshToken?.token)
        }
    }
    
    /// Backing networking client instance variable.
    fileprivate static var _client: Client?
    
    /// BLOCKv networking client.
    ///
    /// The networking client must support a platform environment change after app launch.
    ///
    /// This requirement is met by using a computed property that dynamically initialises a
    /// new client if the instance variable `_client` has been set to `nil`.
    ///
    /// The affords the caller the ability to set the platform environment and be sure to
    /// receive a new networking client instance.
    internal static var client: Client {
        get {
            // check if a new instance must be initialized
            if _client == nil {
                // init a new instance
                _client = Client(config: BLOCKv.clientConfiguration)
                return _client!
            } else {
                // return the backing instance
                return _client!
            }
        }
    }
    
//    fileprivate static var _socketClient: WebSocketManager?
//    
//    internal static var socketClient {
//        get {
//            
//        }
//    }
    
    //static let socket = WebSocketManager()
    
    // This may fail if we don't yet have a refresh token.
    
//    BLOCKv.getAccessToken { (success, accessToken) in
//    guard success, let token = accessToken else {
//    print("ERROR! Cannot fetch access token.")
//    return
//    }
//    
//    self.webSocketManager = WebSocketManager(serverHost: "wss://ws.blockv.net/ws",
//    appId: MyAppID,
//    accessToken: token)
//    }
    
    
    /// Called to reset the SDK.
    internal static func reset() {
        // remove all credentials
        CredentialStore.clear()
        // remove client instance - force re-init on next access
        self._client = nil
    }
    
    // - Public Lifecycle
    
    /*
     Maybe the credential store should be responsible for broadcasting when authorisation changes?
     */
    
    /// Called when authorisation occurs.
    internal func onLogin() {
        
    }
    
    /// Called when authorisation is revoked.
    internal func onLogout() {
        
    }
        
    /// Boolean indicating whether a user is logged in. `true` if logged in. `false` otherwise.
    public static var isLoggedIn: Bool {
        // ensure a token is present
        guard let refreshToken = CredentialStore.refreshToken?.token else { return false }
        // ensure a valid jwt
        guard let refreshJWT = try? decode(jwt: refreshToken) else { return false }
        // ensure still valid
        return !refreshJWT.expired
    }
    
    @available(*, deprecated, message: "This is an unsupported feature of the SDK and may be removed in a future release.")
    /// Retrieves and refreshes the SDKs access token.
    ///
    /// - Important:
    /// This function should only be called if you have a well defined reason for obtaining an
    /// access token.
    ///
    /// - Parameter completion: The closure to call once an access token has been obtained
    /// form the BLOCKv platform.
    public static func getAccessToken(completion: @escaping (_ success: Bool, _ accessToken: String?) -> Void) {
        BLOCKv.client.getAccessToken(completion: completion)
    }
    
    // MARK: - Configuration
    
    /// Configures the SDK with your issued app id.
    ///
    /// Note, as a viewer, `configure` should be the first method call you make  on the BLOCKv SDK.
    /// Typically, you would call `configure` in `application(_:didFinishLaunchingWithOptions:)`
    public static func configure(appID: String) {
        self.appID = appID
    }
    
    /// Sets the BLOCKv platform environment.
    ///
    /// By setting the environment you are informing the SDK which BLOCKv
    /// platform environment to interact with.
    ///
    /// Typically, you would call `setEnvironment` in `application(_:didFinishLaunchingWithOptions:)`.
    @available(*, deprecated, message: "BLOCKv now defaults to production. You may remove this call.")
    public static func setEnvironment(_ environment: BVEnvironment) {
        self.environment = environment
        
        //FIXME: *Changing* the environment should nil out the client and access credentials.
        
    }
    
    // MARK: - Resources
    
    /// Closure that encodes a given url using a set of asset providers.
    ///
    /// If none of the asset providers are able to perform encoding, the original URL is returned.
    internal static let blockvURLEncoder: URLEncoder = { (url, assetProviders) in
        let provider = assetProviders.first(where: { $0.isProviderForURL(url) })
        return provider?.encodedURL(url) ?? url
    }
    
    // MARK: - Init
    
    /// BLOCKv follows the static pattern. Instance creation is not allowed.
    fileprivate init() {}
    
}


// MARK: - Print Helpers

func printBV(info string: String) {
    print("\nBV SDK > \(string)")
}

func printBV(error string: String) {
    print("\nBV SDK >>> Error: \(string)")
}
