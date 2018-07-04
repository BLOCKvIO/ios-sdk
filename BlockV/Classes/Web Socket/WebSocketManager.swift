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
import Starscream
import Signals

/*
 Important points:
 - Viewer may subscribe to singals before the Web socket has connected.
 - A single shared OAuth2Handler instance is used to handle access token refresh.
 - Attempting to connect to the Web socket before the user has authenticated (i.e. is able
 to fetch access tokens) will result a connection error. Beware of a loop!
 - When the viewer changes users, the Web socket MUST reconnect using the new user's access token.
 
 Future items:
 - Parse socket messages into native models on a background queue.
 ... - See: https://github.com/daltoniam/Starscream#custom-queue
 - Ensure cleaned up after web socket disconnect. Possibly remove subscribers to signals?
 */

/// Responsible for communitating with the BLOCKv Web socket server.
///
/// - important: There should only ever be a single instance within the BLOCKv SDK.
///
/// ## Features
///
/// - Create and manages the socket connection.
/// - Built-in retry mechanism using exponential backoff.
///
/// ## Consumers
///
/// Consumers may subscribe to the following events:
///
/// Lifecycle events:
/// - onConnected
/// - onDisconnected
///
/// Platform events:
/// - onMessageReceivedRaw
/// - onInventoryUpdate
/// - onVatomStateUpdate
/// - onActivityUpdate
public class WebSocketManager {

    /// Models the type of events sent over the Web socket.
    enum WSMessageType: String {
        /// INTERNAL: Broadcast on initial connection to the socket.
        case info        = "info"
        /// Inventory event
        case inventory   = "inventory"
        /// Vatom state update event
        case stateUpdate = "state_update"
        /// Activity event
        case activity    = "my_events"
    }

    // MARK: - Signals

    // - Platform Events

    /// Fires when the Web socket receives **any** message.
    ///
    /// The Signal is generic over a dictionary [String : Any] which contains the raw message.
    public let onMessageReceivedRaw = Signal<[String: Any]>()

    /// Fires when the Web socket receives an **inventory** update event.
    public let onInventoryUpdate = Signal<WSInventoryEvent>()

    /// Fires when the Web socket recevies a vAtom **state update** event.
    public let onVatomStateUpdate = Signal<WSStateUpdateEvent>()

    /// Fires when the Web socket receives an **activity** update event.
    public let onActivityUpdate = Signal<WSActivityEvent>()

    // - Lifecycle

    /// Fires when the Web socket has established a connection.
    public let onConnected = Signal<Void>()
    /// Fires when the Web socket has disconnected.
    public let onDisconnected = Signal<Error?>()

    // MARK: - Properties

    /// Boolean indicating whether the socket is connected.
    public var isConnected: Bool {
        return socket?.isConnected ?? false
    }

    /// JSON decoder configured for the BLOCKv Web socket server.
    private lazy var blockvJSONDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Web socket instance
    private var socket: WebSocket?
    private let baseURLString: String
    private let appID: String
    private let oauthHandler: OAuth2Handler

    /// Boolean controlling whether this manager will automatically and opportunistically
    /// attempt to re-establish a connection. For example, after the app receives a
    /// `UIApplicationDidBecomeActive` event.
    ///
    /// This is in an attempt to improve the reliability of the Web socket by attempting
    /// to ensure the Web socket is connected (if the Viewer expects it to be).
    ///
    /// Logic:
    /// Should be set to `true` when the viewer calls `connect()`.
    /// Should be set to `false` when the viewer calls `disconnect()`
    private var shouldAutoConnect: Bool = false

    /// Boolean indicating whether the access token is beign refreshed.
    private var isRefreshingAccessToken: Bool = false

    // MARK: - Initialisation

    internal init(baseURLString: String, appID: String, oauthHandler: OAuth2Handler) {
        self.baseURLString = baseURLString
        self.appID = appID
        self.oauthHandler = oauthHandler

        // Listen for notifications for when the app becomes active
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive, object: nil)

    }

    // MARK: - Lifecycle

    /// Starts the process of establishing a connection to the Web socket server.
    ///
    /// It is safe to call this method multiple times. The connection will only be re-established if the
    /// socket is currenlty *disconnected*.
    ///
    /// - note: Establishing a network connection is an asynchronous task — typically in the order of
    /// seconds, but is of course, network dependent. Subscribe to `onConnected()` to receive a signal
    /// when the socket establishes a connection.
    ///
    /// - important: A connection can only be established if the user has an **authenticated** session.
    public func connect() {

        /*
         There are 2 challenges to solve here (if needed):
         
         1. The connect method is syncronous - this means the caller does not know when the socket
         actually connects. For this, they need to listen for `onConnected()` - I am happy with this.
         2. Retrying the connection in the event the connection drops
         - Should the connection be retired if there is a problem with the auth (i.e. a 400 range error)?
         ... - This may cause an infinte loop.
         ... - The caller should rather be informed of a problem (e.g. user must be authenticated).
         - Maybe the connection should only be retried on 500s (i.e. the server is offline).
         */

        DispatchQueue.mainThreadPrecondition()

        // raise the flag that the viewer has requested a connection
        self.shouldAutoConnect = true
        // prevent connection attempt if connected
        if socket?.isConnected == true { return }

        // prevent connection attempt if connection is in progress
        if self.isRefreshingAccessToken == true { return }
        isRefreshingAccessToken = true

        printBV(info: "Web socket - Establishing a connection.")

        // fetch a refreshed access token
        self.oauthHandler.forceAccessTokenRefresh { (success, accessToken) in

            self.isRefreshingAccessToken = false

            // ensure no error
            guard success, let token = accessToken else {
                printBV(error: "Web socket - Cannot fetch access token. Socket connection cannot be established.")
                return
            }

            // initialise an instance of a web socket
            self.socket = WebSocket(url: URL(string: self.baseURLString + "?app_id=\(self.appID)" + "&token=\(token)")!)
            self.socket?.delegate = self
            self.socket?.connect()

        }

    }

    /// Attempts to disconnect from the Web socket server.
    ///
    /// - note: Disconnecting a network connection is an asynchronous task — typically in the order of
    /// seconds, but is of course, network dependent. Subscribe to `onDisconnected()` to receive a signal
    /// when the socket closes the connection.
    public func disconnect() {

        DispatchQueue.mainThreadPrecondition()

        self.shouldAutoConnect = false
        socket?.disconnect()
    }

    @objc
    private func handleApplicationDidBecomeActive() {
        // reset exponential backoff variables
        //        _retryTimeInterval = 1
        //        _retryCount = 0
        // connect (if not already connected)
        self.connect()
    }

}

// MARK: - Extension WebSocket Delegate

extension WebSocketManager: WebSocketDelegate {

    public func websocketDidConnect(socket: WebSocketClient) {
        printBV(info: "Web socket - Connected")
        self.onConnected.fire(())
    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {

        if let err = error as? WSError {
            printBV(info: "Web socket - Disconnected: \(err.message)")
        } else if let err = error {
            printBV(info: "Web socket - Disconnected: \(err.localizedDescription)")
        } else {
            printBV(info: "Web socket - Disconnected")
        }

        // Fire an error informing the observers that the Web socket has disconnected.
        self.onDisconnected.fire((nil))

        //TODO: The Web socket should reconnect here:
        // The app may fire this message when entering the foreground
        // (after the Web socket was disconnected after entering the background).

    }

    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        //printBV(info: "Web socket - Did receive text: \(text)")
        parseMessage(text)
    }

    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        // N/A - Web socket does not send data messages.
    }

    // MARK: Message Parsing

    private func parseMessage(_ text: String) {

        //TODO: Move parsing to a background thread.

        // parse to data
        guard
            let data = text.data(using: .utf8) else {
                printBV(error: "Web socket - Parse error - Unable to convert string to data: \(text)")
                return
        }

        // parse data to dictionary
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
            let jsonDictionary = jsonObject as? [String: Any] else {
                printBV(error: "Web socket - Unable to parse JSON data.")
                return
        }

        //print(jsonDictionary.prettyPrintedJSON!)

        /*
         Fire the signal using the message in it's 'raw' form.
         Allows viewers to handle the socket messages as they please.
         */
        self.onMessageReceivedRaw.fire(jsonDictionary)

        // - Parse event models

        // find message type
        guard let typeString = jsonDictionary["msg_type"] as? String else {
            printBV(error: "Web socket - Cannot parse 'msg_type'.")
            return
        }

        // ensure message type is known
        switch WSMessageType(rawValue: typeString) {
        case .some(let messageType):

            switch messageType {
            case .info:
                break
                //printBV(info: payload.description)

            case .inventory:
                do {
                    let inventoryEvent = try blockvJSONDecoder.decode(WSInventoryEvent.self, from: data)
                    //TODO: Set an enum `event` = .added or .removed - this will require the user id (decode the jwt).
                    self.onInventoryUpdate.fire(inventoryEvent)
                } catch {
                    printBV(error: error.localizedDescription)
                }

            case .stateUpdate:
                do {
                    let stateUpdateEvent = try blockvJSONDecoder.decode(WSStateUpdateEvent.self, from: data)
                    self.onVatomStateUpdate.fire(stateUpdateEvent)
                } catch {
                    printBV(error: error.localizedDescription)
                }

            case .activity:
                do {
                    // FIXME: Allow resources to be encoded.
                    let activityEvent = try blockvJSONDecoder.decode(WSActivityEvent.self, from: data)
                    self.onActivityUpdate.fire(activityEvent)
                } catch {
                    printBV(error: error.localizedDescription)
                }

            }
        default:
            printBV(error: "Unrecognised message type: \(typeString).")
            return
        }

    }

}
