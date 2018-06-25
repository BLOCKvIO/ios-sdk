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
    
    /// Called to reset the SDK.
    internal static func reset() {
        // remove all credentials
        CredentialStore.clear()
        // remove client instance - force re-init on next access
        self._client = nil
    }
    
    // - Public
    
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
    /// Note, as a viewer, `configure` should be the first method call you make on the BLOCKv SDK.
    /// Typically, you would call `configure` in `application(_:didFinishLaunchingWithOptions:)`
    ///
    /// This method must be called ONLY once.
    public static func configure(appID: String) {
        self.appID = appID
        
        // NOTE: Since `configure` is called only once in the app's lifecycle. We do not need to worry about multiple registrations.
        NotificationCenter.default.addObserver(BLOCKv.self,
                                               selector: #selector(handleUserAuthorisationRequired),
                                               name: Notification.Name.BVInternal.UserAuthorizationRequried,
                                               object: nil)
    }
    
    /// Called when the networking client detects the user is unathorized.
    ///
    /// This method perfroms a clean up operation before notifying the viewer that the SDK requires
    /// user authorization.
    ///
    /// - important: This method may be called multiple times. For example, consider the case where
    /// multiple requests fail due to the refresh token being invalid.
    @objc
    private static func handleUserAuthorisationRequired() {
        
        printBV(info: "Authorization - User is unauthorized.")
        
        // only notify the viewer if the user is currently authorized
        if isLoggedIn {
            // perform interal clean up
            reset()
            // call the closure stored in `onLogout`
            onLogout?()
        }
        
    }
    
    /// Holds a closure to call on logout
    public static var onLogout: (() -> Void)?
    
    /// Sets the BLOCKv platform environment.
    ///
    /// By setting the environment you are informing the SDK which BLOCKv
    /// platform environment to interact with.
    ///
    /// Typically, you would call `setEnvironment` in `application(_:didFinishLaunchingWithOptions:)`.
    @available(*, deprecated, message: "BLOCKv now defaults to production. You may remove this call to set the environment.")
    public static func setEnvironment(_ environment: BVEnvironment) {
        self.environment = environment
    }
    
    // MARK: - Resources
    
    /// Closure that encodes a given url using a set of asset providers.
    ///
    /// If non of the asset providers are able to perform encoding, the original URL is returned.
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
