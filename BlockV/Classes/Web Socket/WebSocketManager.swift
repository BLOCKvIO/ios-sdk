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
 - Web socket should handle enexpected disconnect. Maybe retry with exponential back off?
 */

/// Responsible for communitating with Web socket server.
///
///
public class WebSocketManager {
        
    /// Models the type of events sent over the Web socket.
    enum WSMessageType: String {
        /// INTERNAL: Broadcast on initial connection to the socket.
        case info           = "info"
        /// Inventory event
        case inventory      = "inventory"
        /// Vatom state update event
        case stateUpdate    = "state_update"
        /// Activity event
        case activity       = "my_events"
    }
    
    // JSON decoder
    let jsonDecoder: JSONDecoder = {
       let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Signals
    
    /// Fires when the Web socket receives **any** message.
    ///
    /// The Signal is generic over a dictionary which contains the raw message.
    public static let onMessageReceivedRaw = Signal<[String : Any]>()
    
    /// Fires when the Web socket receives an **inventory** event.
    public static let onInventoryEvent = Signal<WSInventoryEvent>()
    
    /// Fires when the Web socket recevies a **state update** event.
    public static let onVatomStateUpdateEvent = Signal<WSStateUpdateEvent>()
    
    /// Fires when the Web socket receives an **activity** event.
    public static let onActivityEvent = Signal<WSActivityEvent>()
    
    // MARK: - Properties
    
    fileprivate var socket: WebSocket
    
    /// Boolean indicating whether the socket is connected.
    var isConnected: Bool {
        return socket.isConnected
    }
    
    // MARK: - Initialisation
    
    public init(serverHost: String, appId: String, accessToken: String) {
        
        // initialise an instance of a web socket
        socket = WebSocket(url: URL(string: serverHost + "?app_id=\(appId)" + "&token=\(accessToken)")!)
        socket.delegate = self
        connect()
        
        // OLD
        //        var request = URLRequest(url: URL(string: "wss://wsdev.blockv.net")!)
        //        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        //        socket = WebSocket(request: request, protocols: ["vatomic"])
        //        socket.delegate = self
        //        socket.connect()
        
    }
    
    // MARK: - Lifecycle
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
}

// MARK: - Extension WebSocket Delegate

extension WebSocketManager: WebSocketDelegate {
    
    public func websocketDidConnect(socket: WebSocketClient) {
        printBV(info: "Web socket - Connected")
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        
        if let e = error as? WSError {
            print("Web socket -  Disconnected: \(e.message)")
        } else if let e = error {
            print("Web socket -  Disconnected: \(e.localizedDescription)")
        } else {
            print("Web socket -  Disconnected")
        }
        
        //TODO: The Web socket should reconnect here:
        // The app may fire this message when entering the foreground (after the Web socket was disconnected after entering the background).
        
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        printBV(info: "Web socket - Did receive message: \(text)")
        parseMessage(text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        printBV(info: "Web socket - Did receive data: \(data.count)")
        //NOTE: Our web socket only returns String type.
    }
    
    // MARK: - Parsing
    
    private func parseMessage(_ text: String) {
        
        // parse to data
        guard
            let data = text.data(using: .utf8) else {
            printBV(error: "Web socket - Parse error - Unable to convert string to data: \(text)")
            return
        }
        
        // parse data to JSON
        guard
            let anyThing = try? JSONSerialization.jsonObject(with: data, options: []),
            let json = anyThing as? [String : Any] else {
            printBV(error: "Web socket - Unable to parse JSON data.")
            return
        }
        
        // find message type
        guard
            let typeString = json["msg_type"] as? String,
            let payload = json["payload"] as? [String : Any] else {
                printBV(error:"Web socket - Cannot parse 'msg_type'.")
                return
        }
        
        /*
         Fire the signal with the web socket message in it's 'raw' form.
         This allows viewers to handle the web socket messages as they please.
         */
        WebSocketManager.onMessageReceivedRaw.fire(json)
        
        // ensure the type is known
        switch WSMessageType(rawValue: typeString) {
        case .some(let type):
            switch type {
            case .info:
                printBV(info: payload.description)
            case .inventory:
                let inventoryEvent = try? jsonDecoder.decode(WSInventoryEvent.self, from: data)
                print(inventoryEvent.debugDescription)
                // TODO: Broadcast / inform delegate
                
            case .stateUpdate:
                let stateUpdateEvent = try? jsonDecoder.decode(WSStateUpdateEvent.self, from: data)
                print(stateUpdateEvent.debugDescription)
                // TODO: Broadcast / inform delegate

            case .activity:
                let activityEvent = try? jsonDecoder.decode(WSActivityEvent.self, from: data)
                print(activityEvent.debugDescription)
                // TODO: Broadcast / inform delegate

            }
        default:
            printBV(error:"Unrecognised message type: \(typeString).")
            return
        }
        
    }
    
}
