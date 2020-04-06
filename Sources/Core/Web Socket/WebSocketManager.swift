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
import UIKit
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
        /// Map event
        case map         = "map"
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

    /// Fires when the Web socket receives a *map* update event for *unowned* vatoms.
    public let onMapUpdate = Signal<WSMapEvent>()

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

    /// Delay option used to determined a reconnect interval (measured in seconds).
    let delayOption = DelayOption.custom(closure: { attempt -> Double in
        // first attemp should reconnect immediately, thereafter consistently every `n` seconds.
        return attempt == 1 ? 0 : 5
    })

    /// Tally of the numnber of reconnect attempts.
    private var reconnectCount: Int = 0

    /// Timer intendend to trigger reconnects.
    private var reconnectTimer: Timer?

    /// Web socket instance
    private var socket: WebSocket?
    private let baseURLString: String
    private let appID: String
    private let oauthHandler: OAuth2Handler

    /// Boolean controlling whether this manager will automatically and opportunistically
    /// attempt to re-establish a connection. For example, after the app receives a
    /// `UIApplicationDidBecomeActive` event.
    ///
    /// - important:
    /// Calling `disconnect()` will set this property to false. At a later point, if you would like to opt into
    /// auto-connect behaviour set `shouldAutoConnect` to `true` before calling `connect()`.
    private var shouldAutoConnect: Bool = true

    /// Boolean indicating whether the access token is beign refreshed.
    private var isRefreshingAccessToken: Bool = false

    // MARK: - Initialisation

    internal init(baseURLString: String, appID: String, oauthHandler: OAuth2Handler) {
        self.baseURLString = baseURLString
        self.appID = appID
        self.oauthHandler = oauthHandler

        // Listen for notifications for when the app becomes active
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
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

        os_log("[%@] Connection requested.", log: .socket, type: .debug, typeName(self))

        DispatchQueue.mainThreadPrecondition()

        // prevent connection if already connected
        // BEWARE: This is not reliable. A web socket struggles to know when it's disconnected.
        if socket?.isConnected == true {
            os_log("[%@] Connection denied. Already connected.", log: .socket, type: .debug, typeName(self))
            return
        }

        // prevent connection attempt if connection is in progress
        if self.isRefreshingAccessToken == true { return }
        isRefreshingAccessToken = true

        os_log("[%@] Fetching access token.", log: .socket, type: .debug, typeName(self))

        // fetch a refreshed access token
        self.oauthHandler.forceAccessTokenRefresh { (success, accessToken) in

            self.isRefreshingAccessToken = false

            // ensure no error
            guard success, let token = accessToken else {
                os_log("[%@]  Fetching access token failed.", log: .socket, type: .error, typeName(self))
                return
            }

            os_log("[%@] Opening connection (%d) with token: %{private}@", log: .socket, type: .debug,
                   typeName(self), self.reconnectCount, token)
            // initialise an instance of a web socket
            self.socket = WebSocket(url: URL(string: self.baseURLString + "?app_id=\(self.appID)" + "&token=\(token)")!)
            self.socket?.delegate = self
            self.socket?.connect()

        }

    }

    private func scheduleReconnect(initialDelay: TimeInterval = 0) {
        
        guard BLOCKv.isLoggedIn else { return }

        self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: initialDelay, repeats: false) { [weak self] _ in

            guard let self = self else { return }

            if self.isConnected { return } // bail out
            self.reconnectCount += 1
            self.connect()
            let nextDelay = self.delayOption.make(self.reconnectCount)
            self.scheduleReconnect(initialDelay: nextDelay)
        }

    }

    /// Attempts to disconnect from the Web socket server.
    ///
    /// Disconnect will timeout of 2 seconds ensuring `onDisconnected()` gets called.
    ///
    /// - note: Disconnecting a network connection is an asynchronous task — typically in the order of
    /// seconds, but is of course, network dependent. Subscribe to `onDisconnected()` to receive a signal
    /// when the socket closes the connection.
    public func disconnect() {

        DispatchQueue.mainThreadPrecondition()

        self.shouldAutoConnect = false
        socket?.disconnect(forceTimeout: 2)
    }

    /// Disconnect without setting `shouldAutoConnect` = false
    func _disconnect() { //swiftlint:disable:this identifier_name
        DispatchQueue.mainThreadPrecondition()
        socket?.disconnect(forceTimeout: 2)
    }

    @objc
    private func handleApplicationDidBecomeActive() {
        // reset exponential backoff variables
        //        _retryTimeInterval = 1
        //        _retryCount = 0
        // connect (if not already connected)
        os_log("[%@]  Application did become active. Attempting reconnect.", log: .socket, type: .debug, typeName(self))
        self.shouldAutoConnect = true
        self.connect()
    }

    @objc
    private func handleApplicationDidEnterBackground() {
        os_log("[%@]  Application did enter background. Attempting disconnect.", log: .socket, type: .debug, typeName(self))
        self.disconnect()
    }

    // MARK: - Commands

    /// Writes a raw payload to the socket.
    func write(_ payload: [String: Any]) {

        DispatchQueue.global(qos: .userInitiated).async {
            // serialize data
            guard let data = try? JSONSerialization.data(withJSONObject: payload) else {
                return
            }
            // write
            self.socket?.write(data: data)
        }

    }

    /// Writes a region command using the specified payload to the socket.
    func writeRegionCommand(_ payload: [String: Any]) {
        // command package
        let commandPackage: [String: Any] = [
            "cmd": "monitor",
            "id": "1",
            "version": "1",
            "type": "command",
            "payload": payload
        ]
        // write
        self.write(commandPackage)

    }

    // MARK: Debugging

    /// Writes a ping frame to the socket.
    func writePing(data: Data = Data(), completion: @escaping () -> Void) {

        // write a ping control frame
        self.socket?.write(ping: data) {
            completion()
        }

    }

}

// MARK: - Extension WebSocket Delegate

extension WebSocketManager: WebSocketDelegate {

    public func websocketDidConnect(socket: WebSocketClient) {
        os_log("[%@] Delegate: Did Connect", log: .socket, type: .debug, typeName(self))

        // invalidate auto-reconnect timer
        self.reconnectTimer?.invalidate()
        self.reconnectTimer = nil
        self.reconnectCount = 0

        self.onConnected.fire(())
    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {

        /*
         Note
         The app may fire this message when entering the foreground (after the Web socket was disconnected after
         entering the background).
         */

        if let err = error as? WSError {
            os_log("[%@] Delegate: Did Disconnect: %@", log: .socket, type: .error, err.message, typeName(self))
        } else if let err = error {
            os_log("[%@] Delegate: Did Disconnect: %@", log: .socket, type: .error, err.localizedDescription, typeName(self))
        } else {
            os_log("[%@] Delegate: Did Disconnect: No Error.", log: .socket, type: .error, typeName(self))
        }

        // Fire an error informing the observers that the Web socket has disconnected.
        self.onDisconnected.fire((nil))

        //
        scheduleReconnect()
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
                os_log("[%@] Delegate: Parse error - Unable to convert string to data: %@", log: .socket, type: .error,
                       typeName(self), text)
                return
        }

        // parse data to dictionary
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
            let jsonDictionary = jsonObject as? [String: Any] else {
                os_log("[%@] Delegate: Parse error - Unable to parse JSON data: %@", log: .socket, type: .error,
                       typeName(self), String(data: data, encoding: .utf8) ?? "--")
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
            os_log("[%@] Decode error: %@", log: .socket, type: .error, typeName(self))
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
                    os_log("[%@] Decode error: %@", log: .socket, type: .error, typeName(self),
                           error.localizedDescription)
                }

            case .stateUpdate:
                do {
                    let stateUpdateEvent = try blockvJSONDecoder.decode(WSStateUpdateEvent.self, from: data)
                    self.onVatomStateUpdate.fire(stateUpdateEvent)
                } catch {
                    os_log("[%@] Decode error: %@", log: .socket, type: .error, typeName(self),
                           error.localizedDescription)
                }

            case .activity:
                do {
                    // FIXME: Allow resources to be encoded.
                    let activityEvent = try blockvJSONDecoder.decode(WSActivityEvent.self, from: data)
                    self.onActivityUpdate.fire(activityEvent)
                } catch {
                    os_log("[%@] Decode error: %@", log: .socket, type: .error, typeName(self),
                           error.localizedDescription)
                }

            case .map:
                do {
                    let mapEvent = try blockvJSONDecoder.decode(WSMapEvent.self, from: data)
                    self.onMapUpdate.fire(mapEvent)
                } catch {
                    os_log("[%@] Decode error: %@", log: .socket, type: .error, typeName(self),
                           error.localizedDescription)
                }

            }
        default:
            os_log("[%@] Unrecognized message type: %@", log: .socket, type: .error, typeName(self),
                   typeName(self), typeString)
            return
        }

    }

}
