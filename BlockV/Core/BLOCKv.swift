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

import os
import Foundation
import Alamofire
import JWTDecode
import CoreData
import Nuke

/*
 Goal:
 
 - BLOCKv should be invariant over App ID and Environment. In other words, the properties may not
 change, once set. Possibly targets for each environemnt?
 
 - Clients shoudl be able to have configure whether a sync stack is setup on session launch.
 */

/// Primary interface into the the BLOCKv SDK.
public final class BLOCKv {

    // MARK: - Properties

    /// The App ID to be passed to the BLOCKv platform.
    ///
    /// Must be set once by the host app.
    internal fileprivate(set) static var appID: String? {
        // willSet is only called outside of the initialisation context, i.e.
        // setting the appID after its init will cause a fatal error.
        willSet {
            if appID != nil {
                assertionFailure("The App ID may be set only once.")
            }
        }

    }
    
    /// Boolean value that controls wheather a synchronization stack is created on session launch.
    ///
    /// App that intend on dispalying vatoms and receiving updates over time should leave this value as `true`.
    /// If your app is not interested in synchronizing with the BLOCKv platform set this value as `false`.
    internal fileprivate(set) static var shouldCreateSyncStackOnSessionLaunch: Bool = true

    //TODO: Detect an environment switch, e.g. dev to prod, reset the client.

    /// The BLOCKv platform environment to use.
    ///
    /// Must be set by the host app.
    internal fileprivate(set) static var environment: BVEnvironment? {
        willSet {
            if environment != nil { reset() }
        }
        didSet {
            os_log("Environment updated:\n%@", log: .lifecycle, type: .debug, environment!.debugDescription)
        }
    }

    // MARK: - Configuration
    
    public struct SessionConfiguration {
        /// App ID which identifes your application to the BLOCKv platform.
        public let appID: String
        
        /// Boolean value that controls whether a synchronization stack is created on session launch, defaults to `true`.
        ///
        /// If your apps intends on dispalying an inventory of vatoms and receiving updates to those vatoms from the BLOCKv platform, set this as `true`.
        public let createSyncStack: Bool
        
        public init(appID: String, createSyncStack: Bool = true) {
            self.appID = appID
            self.createSyncStack = createSyncStack
        }
        
    }

    /// Configures the SDK with your issued app id.
    ///
    /// Note, as a viewer, `configure` should be the first method call you make on the BLOCKv SDK.
    /// Typically, you would call `configure` in `application(_:didFinishLaunchingWithOptions:)`.
    ///
    /// - important
    /// This method must be called ONLY once.
    ///
    /// - Parameter config: An instance of `SessionConfiguration` containing the data and setting to setup the BLOCKv SDK.
    public static func configure(with config: SessionConfiguration) {
        self.appID = config.appID
        self.shouldCreateSyncStackOnSessionLaunch = config.createSyncStack

        // - CONFIGURE ENVIRONMENT

        // only modify if not set
        if environment == nil {

            /*
             The presense of the ENVIRONMENT_MAPPING user defined plist key allows the SDK to use pre-mapped
             environments. This is only used internally for the BLOCKv apps. 3rd party API consumers must always use
             the production environment.
             */

            // check if the plist contains a user defined key (internal only)
            if let environmentString = Bundle.main.infoDictionary?["ENVIRONMENT_MAPPING"] as? String,
                let mappedEnvironment = BVEnvironment(rawValue: environmentString) {

                #if DEBUG
                // environment for experimentation (safe to modify)
                self.environment = .production
                #else
                // pre-mapped environment (do not modify)
                self.environment = mappedEnvironment
                #endif

            } else {

                // 3rd party API consumers must always point to production.
                self.environment = .production

            }

        }

        // NOTE: Since `configure` is called only once in the app's lifecycle. We do not
        // need to worry about multiple registrations.
        NotificationCenter.default.addObserver(BLOCKv.self,
                                               selector: #selector(handleUserAuthorisationRequired),
                                               name: Notification.Name.BVInternal.UserAuthorizationRequried,
                                               object: nil)

        // configure in-memory cache (store processed images ready for display)
        ImageCache.shared.costLimit = ImageCache.defaultCostLimit()

        // configure http cache (store unprocessed image data at the http level)
        DataLoader.sharedUrlCache.memoryCapacity = 80 * 1024 * 1024  // 80 MB
        DataLoader.sharedUrlCache.diskCapacity = 180  // 180 MB

        // handle session launch
        if self.isLoggedIn {
            self.onSessionLaunch()
        }

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
    static var client: Client {
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
    //TODO: What if the viewer subscribes to an event before auth (login/reg) has occured?
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
        // remove region caches
        try? FileManager.default.removeItem(at: Region.recommendedCacheDirectory)
        // remove cached responses
        DataLoader.sharedUrlCache.removeAllCachedResponses()
        // nil out client
        self._client = nil
        // disconnect and nil out socekt
        self._socket?.disconnect()
        self._socket = nil
        // clear data pool
        DataPool.clear()
        // clear defaults
        BVDefaults.shared.clear()
        // teardown sync stack
        self.teardownSyncStack()

        os_log("Resetting SDK", log: .lifecycle, type: .debug)
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

    /// Called when the networking client detects the user is unauthenticated.
    ///
    /// This method perfroms a clean up operation before notifying the viewer that the SDK requires
    /// user authentication.
    ///
    /// - important: This method may be called multiple times. For example, consider the case where
    /// multiple requests fail due to the refresh token being invalid.
    @objc
    private static func handleUserAuthorisationRequired() {

        // only notify the viewer if the user is currently authorized
        if isLoggedIn {
            // perform interal clean up
            reset()
            // call the closure stored in `onLogout`
            onLogout?()
        }

    }

    /// Called when the user authenticates (logs in).
    ///
    /// - important:
    /// This method is *not* called when the access token refreshes.
    static internal func onLogin() {
        
        //TODO: Update `onLogin` to have a userID argunment (or is there a better way to fetch the user?)
        
        //FIXME: Why was I moving this here?
//        self.createBLOCKVContainer(userID: "27e23978-1fd0-4257-b44d-2129be76c55c") { persistentContainer in
//            //
//        }

        // stand up the session
        self.onSessionLaunch()

    }

    /// Holds a closure to call on logout
    public static var onLogout: (() -> Void)?
    
    /// Session launch arguments.
    public struct SessionArguments {
        
        /// User ID of the launched session.
        public let userID: String
        
        /// Reference to the persistent container of the underlying CoreData stack. If `shouldCreateSyncStackOnSessionLaunch` was
        /// set as `false` durign configuration, then this reference wil be `nil`.
        public let persistentContainter: NSPersistentContainer?
        
    }
    
    /// Holds a single shot closure that is called on session lauch.
    public static var sessionDidLaunch: ((_ arguments: SessionArguments) -> Void)?

    /// This function is called everytime a user session is launched.
    ///
    /// A 'session launch' means the user has logged in (received a new refresh token), or the app has been cold
    /// launched with an existing *valid* refresh token.
    ///
    /// - note:
    /// This is slightly broader than 'log in' since it includes the lifecycle of the app. This function is responsible
    /// for creating objects which are depenedent on a user session, e.g. data pool.
    ///
    /// Its compainion `onSessionTerminated` is `onLogout` since there is no app event signalling app termination.
    ///
    /// Triggered by:
    /// - User authentication
    /// - App launch & user is authenticated
    static private func onSessionLaunch() {

        guard let refreshToken = CredentialStore.refreshToken?.token else {
            fatalError("Invlalid session")
        }

        guard let claim = try? decode(jwt: refreshToken).claim(name: "user_id"), let userId = claim.string else {
            fatalError("Invalid cliam")
        }

        // standup the client & socket
        _ = client
        _ = socket.connect()

        // standup data pool
        DataPool.sessionInfo = ["userID": userId]
        
        if shouldCreateSyncStackOnSessionLaunch {
            
            // create blockv stack
            self.createBLOCKVContainer(userID: userId) { container in
                let launchArguments = SessionArguments(userID: userId, persistentContainter: container)
                self.sessionDidLaunch?(launchArguments)
            }
            
        } else {
            let launchArguments = SessionArguments(userID: userId, persistentContainter: nil)
            self.sessionDidLaunch?(launchArguments)
        }
        
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
    
    // MARK: - Core Data
    
    static var persistentContainer: NSPersistentContainer!
    static var syncCoordinator: SyncCoordinator?
    
    //FIXME: TEMPORARY METHOD TO HELP TESTING
    public static func refresh() {
        syncCoordinator?._refresh()
    }
    
    /// pass through application events
    public static func applicationDidEnterBackground(_ application: UIApplication) {
        persistentContainer.viewContext.batchDeleteObjectsMarkedForLocalDeletion()
        persistentContainer.viewContext.refreshAllObjects()
    }
    
    /// pass through application events
    public static func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        persistentContainer.viewContext.refreshAllObjects()
    }

    /*
     - This method should only be called *after* a user has been logged in.
     */

    /// Create an `NSPersistentContainer` for the user's inventory.
    ///
    /// Creates and configures the sync coordinator
    ///
    /// - Parameter userID: User ID.
    /// - Parameter completion: Completes with a pointer to the `NSPersistentContainer` used the sync framework. As a viewer, use the container's
    ///                         `viewContext` to drive your view controller graph.
    static func createBLOCKVContainer(userID: String, completion: @escaping (NSPersistentContainer) -> ()) {
        
        //FIXME: This does not work because the model is part of a pod (and being vended as a resource)
//        let container = NSPersistentContainer(name: "Model") // same name as the '.xcdatamodeld' file
//        container.loadPersistentStores { _, error in
//            guard error == nil else { fatalError("Failed to load store: \(error!)") }
//            DispatchQueue.main.async { completion(container) }
//        }
        
        print("Asset Providers", CredentialStore.assetProviders)
        
        /*
         Here we create the container.
         This stands up the CoreData stack.
         1. Find the Core Data Model - file containing the definition of the application's *data structure*
         2. Persistent Store - Database - The file containing tha application's *data*. This persists the data.
         3. Managed Object - Object holding a set of properties from the Persistent Store.
         4. Managed Object Context - ScratchPad - An area in memory where you interact with Managed Objects.
         5. Persistent Store Coordinator - An object that mediates between the Persistent Store(s) and the Managed Object Context(s).
         6. Entity - Defines Managed Objects.
         7. Relationship - Joins Entities.
         8. Fetch Request - A way of retrieving managed objects from a Peristent Store.
         9. Predicate - Filter - A way of filtering which Managed Objects that a fetch request will return.
         10. Sort Descriptor - A way of ordering the managed objects that a Fetch Request will return.
         */
        self.persistentContainer = makeBlockvContainer()
        
        /*
         Somehow need to ensure the web socket is up before the sync coordinator is up and running.
         
         BUT, the user must see vatoms before the socket is up and running.
         
         This does not prevent the UI from pulling already persisted data, right? It just mean the sync coordinator
         is dependent on the configuration of the socket.
         */
        
        /*
         This should become the new instance through which all networking is done, yes?
         */
        let blockvRemote = BLOCKvRemote(client: self.client)
        
        /*
         SocketSubscription need to get the notifications (currently signals) coming out of the WebSocketManager.
         Options:
         1. Subscribe to signals here (shown below)
         2. Delegate?
         > WebSocketManager is not condusive to the delegate pattern (1:1) since it's a broadcaster (1:N).
         
         How is SocketSubscription going to broadcast it's messages? It's queuing events on its own private queue.
         How many component inside sync will use it? At the moment, I think it's only Sync coordinator. So the delegate
         pattern might be ok.
         - What about when there are multiple regions (not only inventory).
         */
        
        // - socket subscription
        let socketSubscription = SocketSubscription(currentUserID: userID, socketManager: self.socket, remote: blockvRemote)
        
        //FIXME: The socket must be connected, and only then should the the synchronization process start.
        
        // - sync coordinator
        self.syncCoordinator = SyncCoordinator(container: persistentContainer, remote: blockvRemote, socket: socketSubscription)
        
        // open the underlying database file
        persistentContainer.loadPersistentStores { _, error in
            guard error == nil else { fatalError("Failed to load store: \(error!)") }
            DispatchQueue.main.async { completion(persistentContainer) }
        }
        
    }
    
    static func teardownSyncStack() {
        
        //TODO: Incomplete - see: https://stackoverflow.com/a/14727650/3589408
        
        /*
         How do I teardown the stack?
         I need to prevent objects elsewhere in the app from accessing the core data items.
         */
        
        self.syncCoordinator?.syncGroup.enter() // prevent any ws events
        self.syncCoordinator?.viewContext.reset()
        self.syncCoordinator?.syncContext.reset()
        self.syncCoordinator = nil
        
        if self.persistentContainer != nil {
            let store = self.persistentContainer.persistentStoreCoordinator.persistentStores[0]
            try! self.persistentContainer.persistentStoreCoordinator.remove(store)
        }
        
        //TODO: Remove the file from disk
        
        
    }
    
}

// MARK: - Logging Helpers

class BVPersistentContainer: NSPersistentContainer {
    override open class func defaultDirectoryURL() -> URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let url = urls[urls.count - 1].appendingPathComponent("BLOCKv")
        return url
    }
}

extension BLOCKv {

    public enum Debug {

        //// Returns the cache size of the face data resource disk caches.
        public static var faceDataResourceCacheSize: UInt64? {
            return try? FileManager.default.allocatedSizeOfDirectory(at: DataDownloader.recommendedCacheDirectory)
        }

        /// Returns the cache size of all data pool region disk caches.
        public static var regionCacheSize: UInt64? {
            return try? FileManager.default.allocatedSizeOfDirectory(at: Region.recommendedCacheDirectory)
        }

        /// Clears all disk caches.
        public static func clearCache() {
            ImageCache.shared.removeAll()
            DataLoader.sharedUrlCache.removeAllCachedResponses()
            try? FileManager.default.removeItem(at: DataDownloader.recommendedCacheDirectory)
            try? FileManager.default.removeItem(at: Region.recommendedCacheDirectory)
            os_log("[Debug] Cleared Cache", log: .lifecycle, type: .debug)
        }

        /// Clear authoarization credentials.
        public static func clearAuthCredentials() {
            CredentialStore.clear()
            os_log("[Debug] Cleared Authorazation Credentials", log: .lifecycle, type: .debug)
        }

    }

}

// MARK: - Logging Helpers

func printBV(info string: String) {
    print("\nBV SDK > \(string)")
}

func printBV(error string: String) {
    print("\nBV SDK >>> Error: \(string)")
}

extension OSLog {
    private static var subsystem = "io.blockv.sdk.core"
    static let lifecycle = OSLog(subsystem: subsystem, category: "lifecycle")
    static let dataPool =  OSLog(subsystem: subsystem, category: "dataPool")
    static let authentication = OSLog(subsystem: subsystem, category: "authentication")
    static let socket = OSLog(subsystem: subsystem, category: "socket")
    static let sync = OSLog(subsystem: subsystem, category: "sync")
}

/// Returns type name.
func typeName(_ some: Any) -> String {
    return (some is Any.Type) ? "\(some)" : "\(type(of: some))"
}
