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

/*
 Goal:
 BLOCKv should be invariant over App ID and Environment. In other words, the properties should
 change, once set. Possibly targets for each environemnt?
 */

/// Primary interface into the the BLOCKv SDK.
public final class BLOCKv {

    // MARK: - Enums

    /// Models the BLOCKv platform environments.
    public enum BVEnvironment {
        /// Stable production environment.
        case production
        /// Unstable development environement (DO NOT USE).
        case development

        /// BLOCKv server base url
        var apiServerURLString: String {
            switch self {
            case .production:  return "https://api.blockv.io"
            case .development: return "https://apidev.blockv.net"
            }
        }

        /// BLOCKv Web socket server base url
        var webSocketURLString: String {
            switch self {
            case .production:  return "wss://newws.blockv.io/ws"
            case .development: return "wss://ws.blockv.net/ws"
            }
        }

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
        didSet { printBV(info: "Environment updated - \(environment!)") }
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

        // NOTE: Since `configure` is called only once in the app's lifecycle. We do not
        // need to worry about multiple registrations.
        NotificationCenter.default.addObserver(BLOCKv.self,
                                               selector: #selector(handleUserAuthorisationRequired),
                                               name: Notification.Name.BVInternal.UserAuthorizationRequried,
                                               object: nil)
    }

    // MARK: - Client

    // FIXME: Should this be nil on logout?
    // FIXME: This MUST become a singleton (since only a single instance should ever exist).
    private static let oauthHandler = OAuth2Handler(appID: BLOCKv.appID!,
                                     baseURLString: BLOCKv.environment!.apiServerURLString,
                                     refreshToken: CredentialStore.refreshToken?.token ?? "")

    /// Computes the configuration object needed to initialise clients and sockets.
    fileprivate static var clientConfiguration: Client.Configuration {
        // ensure host app has set an app id
        let warning = """
            Please call 'BLOCKv.configure(appID:)' with your issued app ID before making network
            requests.
            """
        precondition(BLOCKv.appID != nil, warning)

        if environment == nil {
            self.environment = .production // default to production
        }

        // return the configuration (inexpensive object)
        return Client.Configuration(baseURLString: BLOCKv.environment!.apiServerURLString,
                                    appID: BLOCKv.appID!)

    }

    /// Backing networking client instance.
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
        // check if a new instance must be initialized
        if _client == nil {
            // init a new instance
            _client = Client(config: BLOCKv.clientConfiguration,
                             oauthHandler: self.oauthHandler)
            return _client!
        } else {
            // return the backing instance
            return _client!
        }
    }

    // MARK: - Web socket

    /*
     Client and Socket are mutually exclusive. That is, one can be created with out the other.
     Both relay on the ability to retrieve an access token. This is provided by a shared instance
     of OAuth2Handler.
     
     
     Even though client and socket are independent, the socket is dependent on the user having an
     authenticated session.
     
     The socket must handle the case where the user is unauthenticated. Particularly around logout.
     */

    /// Backing Web socket instance.
    ///
    /// Must be torn down when the user logs out.
    ///
    /// The Web socket is independent of the `client`. However, it is bound to
    /// the user being authenticaated.
    fileprivate static var _socket: WebSocketManager?

    //TODO: What if this is accessed before the client is accessed?
    //TODO: What if the viewer suscribes to an event before auth (login/reg) has occured?
    public static var socket: WebSocketManager {
        if _socket == nil {
            _socket = WebSocketManager(baseURLString: self.environment!.webSocketURLString,
                                       appID: self.appID!,
                                       oauthHandler: self.oauthHandler)
            return _socket!
        } else {
            return _socket!
        }
    }

    // MARK: - Lifecycle

    /// Call to reset the SDK.
    internal static func reset() {
        // remove all credentials
        CredentialStore.clear()
        // nil out client
        self._client = nil
        // disconnect and nil out socekt
        self._socket?.disconnect()
        self._socket = nil

        printBV(info: "Reset")
    }

    // - Public Lifecycle

    /// Boolean indicating whether a user is logged in. `true` if logged in. `false` otherwise.
    public static var isLoggedIn: Bool {
        // ensure a token is present
        guard let refreshToken = CredentialStore.refreshToken?.token else { return false }
        // ensure a valid jwt
        guard let refreshJWT = try? decode(jwt: refreshToken) else { return false }
        // ensure still valid
        return !refreshJWT.expired
    }

    @available(*, deprecated, message: "Unsupported feature of the SDK and may be removed in the future.")
    /// Retrieves a refreshed access token.
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
    @available(*, deprecated, message: "BLOCKv now defaults to production. You may remove this call.")
    public static func setEnvironment(_ environment: BVEnvironment) {
        self.environment = environment

        //FIXME: *Changing* the environment should nil out the client and access credentials.

    }

    // MARK: - Resources

    enum URLEncodingError: Error {
        case missingAssetProviders
    }

    /// Encodes the URL with the with the available asset providers.
    ///
    /// - note: Not all URLs require asset provider encoding.
    ///
    /// If the SDK does not have any asset provider credentials the method will throw.
    public static func encodeURL(_ url: URL) throws -> URL {
        let assetProviders = CredentialStore.assetProviders
        if assetProviders.isEmpty { throw URLEncodingError.missingAssetProviders }
        let provider = assetProviders.first(where: { $0.isProviderForURL(url) })
        return provider?.encodedURL(url) ?? url
    }

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
