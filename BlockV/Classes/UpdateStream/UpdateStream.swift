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

extension UpdateStream {

    enum WebSocketMessageType: String {
        case systemMessge   = "system_message"
        case inventory      = "inventory"
        case stateUpdate    = "state_update"
        case rpc            = "rpc"
        case myEvents       = "my_events"
        case info           = "info"
        case error          = "error"
    }
    
}

/*
 Refactor the Web socket to work off the access token supplied when the connection was made.
 
 This token contains the user id. This user id should be used to determin if vatoms were added o
 removed from the user's inventory.
 */


/// This class is responsible for managing the connection to the Web socket service,
/// and processing the events it receives from that service.
final class UpdateStream: WebSocketDelegate {
    
    typealias JSONDictionary = [String : Any]
    
    // MARK: - Properties
    
    fileprivate var serverAddress: String
    
    var socket: WebSocket?
    
    // ISO 8601 (pre iOS 10)
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    // MARK: - Initialisation
    
    /// Start the connection.
    init(serverAddress: String) {
        super.init()
    
        self.serverAddress = serverAddress
    }
    
    /// Connection no longer required.
    deinit {
        disconnect()
    }
    
    // MARK: - Methods
    
    /// Creates the connection.
    @objc
    func connect(accessToken: String) {
        
        eventHistory.append(WebSocketEvent(appTimestamp: Date(), serverTimeStamp: nil, type: .connecting, payload: nil))
        log.info("Connecting to: \(Vatomic.environment.websocketAddress.description)")
        
        // create socket from a request
        var request = URLRequest(url: URL(string: Vatomic.environment.websocketAddress)!)
        // add jwt header
        request.addValue("Bearer " + (Vatomic.shortAccessToken ?? ""), forHTTPHeaderField: "Authorization")
        socket = WebSocket(request: request, protocols: ["vatomic"])
        socket?.delegate = self
        socket?.connect()
        
        
        
        var req = URLRequest(url: URL(string: "wss://ws.blockv.io")!)
        
    }
    
    @objc
    func connect1() {
        
        
        
    }
    
    func disconnect() {
        
        // remove pending calls
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        // disconnect from socket
        socket?.delegate = nil
        socket?.disconnect()
        
    }
    
    /// Called when the WebSocket connects.
    func websocketDidConnect(socket: WebSocketClient) {
        
        //        var murmur = Murmur(title: "Web socket connected.")
        //        murmur.backgroundColor = UIColor.bvSeafoamBlue
        //        // Show and hide a message after delay
        //        Whisper.show(whistle: murmur, action: .show(0.5))
        
        eventHistory.append(WebSocketEvent(appTimestamp: Date(), serverTimeStamp: nil, type: .connected, payload: nil))
        NotificationCenter.default.post(name: Notification.Name.BlockvDebug.WebSocketConnected, object: nil)
        
        log.info("Connected.")
        
        // Create login payload
        let payload = [
            "action": "login",
            "appID": Vatomic.appID
        ]
        
        // Create JSON data
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            NSLog("Strange error: Unable to convert payload to JSON.")
            return
        }
        
        // Convert to string
        guard let dataStr = String(data: data, encoding: String.Encoding.utf8) else {
            NSLog("Strange error: Unable to convert data to string.")
            return
        }
        
        let logString = """
        Performing Login
        \t Data ・ \(payload)
        """
        log.info(logString)
        
        // Send login payload
        socket.write(string: dataStr)
        
        // Trigger an inventory update, in case state changed while we were gone
        //        VatomInventory.refreshAll()
        
    }
    
    /// Called when the WebSocket is disconnected.
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        
        eventHistory.append(WebSocketEvent(appTimestamp: Date(), serverTimeStamp: nil, type: .disconnected, payload: nil))
        NotificationCenter.default.post(name: Notification.Name.BlockvDebug.WebSocketDisconnected, object: nil)
        log.warning("Disconnected.\n\tError \(String(describing: error))")
        
        // try again soon
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(connect), object: nil)
        self.perform(#selector(connect), with: nil, afterDelay: 5)
        
        // show and hide a message after delay
        //        var murmur = Murmur(title: "Web socket disconnected.")
        //        murmur.backgroundColor = UIColor.bvBrownishOrange
        //        Whisper.show(whistle: murmur, action: .show(1.5))
        
    }
    
    /// Called when the WebSocket receives text
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        
        // Parse payload to NSData
        guard let data = text.data(using: String.Encoding.utf8) else {
            log.error("Strange error: Unable to convert string to data: %@", text)
            return
        }
        
        // Parse payload to JSON
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary else {
            log.error("WebSocket error: Unable to parse JSON data")
            return
        }
        
        // get message info
        guard let typeString = json?["msg_type"] as? String else {
            log.error("Cannot parse message type json.")
            return
        }
        
        // ensure the type is known
        guard let type = WSMessageType(rawValue: typeString) else {
            log.error("Unrecognised message type: \(typeString).")
            return
        }
        
        let payload = json?["payload"] as? JSONDictionary ?? [:]
        
        // broadcast
        NotificationCenter.default.post(name: Notification.Name.BlockvDebug.WebSocketDidReceiveMessage, object: nil)
        
        var whenModified: Date?
        if let newProperties = payload["new_object"] as? JSONDictionary {
            if let date = newProperties["when_modified"] as? String {
                whenModified = dateFormatter.date(from: date)
            }
        }
        eventHistory.append(WebSocketEvent(appTimestamp: Date(), serverTimeStamp: whenModified, type: .message(type), payload: payload))
        
        let logString = """
        Type: \(type.rawValue)
        \t Data ・ \(payload)"
        """
        
        log.verbose(logString)
        
        // type specific logic
        switch type {
            
        case .systemMessge:
            
            // Show system message
            let text = payload["text"] as? String ?? ""
            UIAlertController.showAlert(title: "System Message", text: text)
            
        case .inventory:
            
            guard let vatomID = payload["id"] as? String else  {
                log.error("Inventory update: Vatom Id missing.")
                return
            }
            
            // check if vatom was removed
            if payload["old_owner"] as? String == Vatomic.user?.userID && payload["new_owner"] as? String != Vatomic.user?.userID {
                
                // broadcast to all inventories a vatom was removed
                NotificationCenter.default.post(name: Notification.Name.VatomicUpdate.VatomRemoved, object: nil, userInfo: ["vatomID": vatomID])
                return
                
                // check if vatom was added
            } else if payload["new_owner"] as? String == Vatomic.user?.userID && payload["old_owner"] as? String != Vatomic.user?.userID {
                
                // get the user who transfered the vAtoms (if available)
                var sendingUser : VatomUser?
                if let id = payload["old_owner"] as? String {
                    if !id.isEmpty {
                        sendingUser = VatomUser.withID(id)
                    }
                }
                
                // ignore vatom if inside a parent vatom
                let parentID = payload["parent_id"] as? String
                if parentID == nil || parentID == "" || parentID == "." {
                    
                    let presentationInfo = payload["presentation"] as? JSONDictionary
                    
                    // create vatom
                    let vatom = Vatom(id: vatomID)
                    if let templateVariation = payload["template_variation"] as? String {
                        vatom.templateVariation = templateVariation
                    }
                    
                    // broadcast a new vatom has been received
                    NotificationCenter.default.post(name: Notification.Name.VatomicUpdate.VatomAdded, object: vatom, userInfo: nil)
                    
                    vatom.onReceived(from: sendingUser, presentationInfo: presentationInfo ?? [:])
                    
                } else {
                    
                    // refresh all inventories
                    VatomInventory.refreshAll()
                    
                }
                
            }
            
        case .stateUpdate:
            
            /*
             Notes:
             > State updates are ONLY received for vAtoms within the current user's inventory.
             > `new_object` contains only modified properties.
             */
            
            // parse data
            guard let vatomID = payload["id"] as? String,
                let newProperties = payload["new_object"] as? JSONDictionary,
                let whenModified = newProperties["when_modified"] as? String else {
                    return
            }
            
            // logging
            if let modified = dateFormatter.date(from: whenModified) {
                let delay = Date().timeIntervalSince(modified)
                let seconds = Double(round(delay * 100)/100)
                log.info("Web socket 'state_update' took: \(seconds) seconds to arrive.")
            }
            
            // broadcast raw state change (viewer may want all the data)
            NotificationCenter.default.post(name: Notification.Name.VatomicVatom.StateChangedRaw, object: nil, userInfo:
                [
                    "vatomID": vatomID,
                    "whenModified": whenModified,
                    "newProperties": newProperties
                ]
            )
            
            // Invesitgate the type of state change in order to broadcast fine grained notifications
            
            guard let desc = newProperties["vAtom::vAtomType"] as? JSONDictionary else { return }
            
            // broadcast drop / pickup
            if let dropped = desc["dropped"] as? Bool {
                if dropped {
                    NotificationCenter.default.post(name: Notification.Name.VatomicVatom.Dropped, object: nil, userInfo:
                        [
                            "vatomID": vatomID,
                            "whenModified": whenModified
                        ]
                    )
                } else {
                    NotificationCenter.default.post(name: Notification.Name.VatomicVatom.PickedUp, object: nil, userInfo:
                        [
                            "vatomID": vatomID,
                            "whenModified": whenModified
                        ]
                    )
                    
                }
            }
            
            // broadcast geo_pos change
            if let geoPos = desc["geo_pos"] as? JSONDictionary, let coordinates = geoPos["coordinates"] as? [Double] {
                
                NotificationCenter.default.post(name: Notification.Name.VatomicVatom.GeoPosition, object: nil, userInfo:
                    [
                        "vatomID": vatomID,
                        "whenModified": whenModified,
                        "lon": coordinates[0],
                        "lat": coordinates[1]
                    ]
                )
                
            }
            
            // broadcast visibility change
            if let visibility = desc["visibility"] as? JSONDictionary, let type = visibility["type"] as? String {
                
                NotificationCenter.default.post(name: Notification.Name.VatomicVatom.Visiblity, object: nil, userInfo:
                    [
                        "vatomID": vatomID,
                        "whenModified": whenModified,
                        "type": type
                    ]
                )
                
            }
            
            /*
             Important
             
             On both Split and Combine actions, the parent Id of the child vAtoms changes and these vAtoms receive this update.
             
             When vAtoms are combined, the child vAtoms `parent_id` field is set. This allows us to notify the parent vatom of
             the change in its contents.
             
             When vAtoms are Split, the parent id is set to `nil`. There is therefore no way of informing the parent of the change
             to its contents.
             */
            
            /*
             This notification may be redundant. `Vatom` is handling the parent ID checks and is broadcasting the relevant
             notifications itself...
             */
            
            // broadcast parent id change
            if let parentID = desc["parent_id"] as? String {
                
                // notify the child vatom is has a new parent id.
                NotificationCenter.default.post(name: Notification.Name.VatomicVatom.NewParentID, object: nil, userInfo:
                    [
                        "vatomID": vatomID,
                        "whenModified": whenModified,
                        "newParentID": parentID,
                        "oldParentID": ""
                    ]
                )
                
                // -----
                
                //TODO: These two need revision.
                
                // notify the child vAtom - whose parent id has changed.
                NotificationCenter.default.post(name: Notification.Name.VatomicVatom.StateChangedWithVatomID, object: nil, userInfo:
                    [
                        "vatomID": vatomID,
                        "whenModified": whenModified
                    ]
                )
                
                /*
                 Note: `parent id` is only avaiable when a child vatom is added. This is a limitation of the web socket.
                 */
                
                // notify the parent vAtom - whose experienced a change in a child vAtom.
                if parentID != "." {
                    NotificationCenter.default.post(name: Notification.Name.VatomicVatom.StateChangedWithVatomID, object: nil, userInfo:
                        [
                            "vatomID": parentID,
                            "whenModified": whenModified
                        ]
                    )
                }
                
            }
            
        case .rpc:
            
            // Notify
            NotificationCenter.default.post(name: .vatomicVatomRPCIncoming, object: nil, userInfo: payload)
            
            // Check for special RPCs
            let rpcName = payload["rpc"] as? String ?? ""
            let rpcData = payload["data"] as? JSONDictionary ?? [:]
            if rpcName == "request_cmd" {
                
                // request info
                guard let vatomID           = rpcData["object_id"] as? String else { return }
                guard let requesterUserID   = rpcData["requestor_id"] as? String else { return }
                guard let actionNameString  = rpcData["cmd"] as? String else { return }
                let actionProps             = rpcData["action_payload"] as? JSONDictionary ?? ["new.owner.id" : requesterUserID]
                
                // check properties are no empty
                if actionNameString.isEmpty || vatomID.isEmpty || requesterUserID.isEmpty {
                    return
                }
                
                // Show consent screen
                let vatom = Vatom(id: vatomID)
                let actionName = ActionName(rawValue: actionNameString)
                RequestActionConsent.requestConsent(forActionNamed: actionName, onVatom: vatom, fromUser: requesterUserID) { (approved) in
                    
                    // Stop if not approved
                    if !approved {
                        return
                    }
                    
                    // Send action
                    vatom.perform(action: actionName, properties: actionProps).catch { error in
                        UIAlertController.showAlert(title: "Unable to " + actionName.rawValue, text: error.localizedDescription)
                    }
                    
                }
                
            }
            
        case .myEvents:
            
            // Broadcast it
            NotificationCenter.default.post(name: Notification.Name.VatomicUpdate.EventReceived, object: payload)
            
        case .info:
            break
            
        case .error:
            
            // parse error
            
            
            // Log error
            log.error("Received error: \(payload)")
        }
    }
    
    
    /// Called when the WebSocket received a data blob */
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        log.info("WebSocket: Got unexpected binary data of length \(data.count)")
    }
    
}
