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
    
    
    /// JSON decoder configured for the BLOCKv Web socket server.
    private lazy var blockvJSONDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Signals
    
    /*
     Signals fire with an error when the Web socket disconnects.
     */
    
    /// Fires when the Web socket receives **any** message.
    ///
    /// The Signal is generic over a dictionary [String : Any] which contains the raw message.
    /// An error will be fired if the Web socket encounters and error.
    public static let onMessageReceivedRaw = Signal<([String : Any]?, Error?)>()
    
    /// Fires when the Web socket receives an **inventory** event.
    public static let onInventoryUpdate = Signal<(WSInventoryEvent?, Error?)>()
    
    /// Fires when the Web socket recevies a **state update** event.
    public static let onVatomStateUpdate = Signal<(WSStateUpdateEvent?, Error?)>()
    
    /// Fires when the Web socket receives an **activity** event.
    public static let onActivityEvent = Signal<(WSActivityEvent?, Error?)>()
    
    // MARK: - Properties
    
    /// Web socket instance
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
        
    }
    
    // MARK: - Lifecycle
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    // Experiment with backoff retry
    //
    
    /*
     -(void)start
     {
     _timeInterval = 0.0;
     [NSTimer scheduledTimerWithTimeInterval:_timeInterval target:self
     selector:@selector(startWithTimer:) userInfo:nil repeats:NO];
     }
     
     -(void)startWithTimer:(NSTimer *)timer
     {
     if (!data.ready) {
     _timeInterval = _timeInterval >= 0.1 ? _timeInterval * 2 : 0.1;
     _timeInterval = MIN(60.0, _timeInterval);
     NSLog(@"Data provider not ready. Will try again in %f seconds.", _timeInterval);
     NSTimer * startTimer = [NSTimer scheduledTimerWithTimeInterval:_timeInterval target:self
     selector:@selector(startWithTimer:) userInfo:nil repeats:NO];
     return;
     }
     ...
     }
     */
    
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
        
        // Fire an error informing the observer that the Web socket is down.
        WebSocketManager.onMessageReceivedRaw.fire((nil, error))
        WebSocketManager.onInventoryUpdate.fire((nil, error))
        WebSocketManager.onVatomStateUpdate.fire((nil, error))
        WebSocketManager.onActivityEvent.fire((nil, error))
        
        //TODO: The Web socket should reconnect here:
        // The app may fire this message when entering the foreground (after the Web socket was disconnected after entering the background).
        
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        printBV(info: "Web socket - Did receive message: \(text)")
        parseMessage(text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        printBV(info: "Web socket - Did receive data: \(data.count)")
        // BLOCKv Web socket does not send data messages.
    }
    
    // MARK: Message Parsing
    
    private func parseMessage(_ text: String) {
        
        // parse to data
        guard
            let data = text.data(using: .utf8) else {
                printBV(error: "Web socket - Parse error - Unable to convert string to data: \(text)")
                return
        }
        
        // parse data to dictionary
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
            let jsonDictionary = jsonObject as? [String : Any] else {
                printBV(error: "Web socket - Unable to parse JSON data.")
                return
        }
        
        //print(jsonDictionary.prettyPrintedJSON!)
        
        /*
         Fire the signal with the web socket message in it's 'raw' form.
         This allows viewers to handle the web socket messages as they please.
         */
        WebSocketManager.onMessageReceivedRaw.fire((jsonDictionary, nil))
        
        // - Parse event models
        
        guard
            // find message type
            let typeString = jsonDictionary["msg_type"] as? String,
            let payload = jsonDictionary["payload"] as? [String : Any] else {
                printBV(error:"Web socket - Cannot parse 'msg_type'.")
                return
        }
        
        // ensure message type is known
        switch WSMessageType(rawValue: typeString) {
        case .some(let messageType):
            
            switch messageType {
            case .info:
                printBV(info: payload.description)
                
            case .inventory:
                do {
                    let inventoryEvent = try blockvJSONDecoder.decode(WSInventoryEvent.self, from: data)
                    WebSocketManager.onInventoryUpdate.fire((inventoryEvent, nil))
                } catch {
                    printBV(error: error.localizedDescription)
                }
                
            case .stateUpdate:
                do {
                    let stateUpdateEvent = try blockvJSONDecoder.decode(WSStateUpdateEvent.self, from: data)
                    print(stateUpdateEvent.vatomProperties)
                    WebSocketManager.onVatomStateUpdate.fire((stateUpdateEvent, nil))
                } catch {
                    printBV(error: error.localizedDescription)
                }
                
            case .activity:
                do {
                    // FIXME: Allow resources to be encoded.
                    let activityEvent = try blockvJSONDecoder.decode(WSActivityEvent.self, from: data)
                    WebSocketManager.onActivityEvent.fire((activityEvent, nil))
                } catch {
                    printBV(error: error.localizedDescription)
                }
                
            }
        default:
            printBV(error:"Unrecognised message type: \(typeString).")
            return
        }
        
    }
    
}
