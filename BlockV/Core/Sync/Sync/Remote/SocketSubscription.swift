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
import BLOCKv


/*
 I am experimenting with a socket notification interface.
 
 1. The sync coordinator/change processor needs to be able to pause and resume the socket
 
 Q: Should the notification stream even be permitted to be paused/resumed? Better would be if the design simply made
 the sync operation mutually exclusive and so all notification were processed afterward.
 it would be really great to not have to pause/resume the notification stream.
 That said, I am not sure how it will work without it...
 */

//protocol NotificationStream {
//
//    /// Pause real-time notification stream.
//    func pause()
//
//    /// Resume real-time notification stream.
//    func resume()
//
//}

// ------


protocol SocketNotificationDrain {
    func didConnect()
    func didDisconnect()
    func didReceiveInventoryUpdate(_ inventoryUpdate: WSInventoryEvent)
    func didReceiveStateUpdate(_ stateUpdate: WSStateUpdateEvent)
    //TODO: map, rpc
//    func didReceiveMapUpdate(_ )
}

extension VatomModel: RemoteRecord {}
extension UnpackedModel: RemoteRecord {}

/*
 # Role
 
 Subsription object responsible for drainig the socket notifications. It's purpose is to queue the ws events
 and pause processing while a synchronization event is happending:
 a) recursive sync
 b) vatom fetch (afte ws inventory add)
 
 It works by managing a private serial queue. Dispatch work items are submitted to the queue to be processed in order.
 The taks in the queue can be suspended and resumed by setting `isPaused`.
 
 Q: Is this overkill? I mean, a simple array queue could also work?
 A: I don't think so, it allows for processing and synchronizing off the main queue.
 
 Notes:
 Q: Connecting and disconnecting from the socket needs to be done on the main queue (due to the locked token refresh
 mechanisms in place)?
 A: No, the OAuthHandler ensure attomic access to the token management block. This means the request, e.g. web
 socket connect, can come from any thread.
 
 Q: How does SyncCoordinator control this object?
 A:
 
 Q: Where does web socket manager fit in with SocketSubscription
 A: This class is reliant on the WebSocketManager. This class is responsible for processing, synchronizing with the API,
 and queuing messages.
 
 Q: Should the socket subcription be a protocol? This way it can be passed as a mockable interface to the sync
 coordinator.
 A:
 
 ## Implicit vs. Explicit subscriptions:
 
 Some subcriptions are implicit, e.g. logging in auto subscribes to invetory, state, and rpc events.
 Other are explicit, e.g. map, must be subcrubed to manually.
 
 Q: How does this class deal with explicit subscriptions? Should it?
 
 */
class SocketSubscription: SocketNotificationDrain {
    
    var webSocketManager: WebSocketManager
    
    /// Central mechanism by which
    ///
    /// Important: Other queue should dispatch asynchronously to this queue since it could be paused at any time.
    private var serialQueue = DispatchQueue(label: "io.blockv.viewer_socket_subscription")
    
    /// Boolean value controlling wheather the subscription is paused.
    var isPaused: Bool = false {
        didSet {
            isPaused ? serialQueue.suspend() : serialQueue.resume()
        }
    }
    
    var currentUserID: String
    
    var remote: RemoteInterface
    
    init(currentUserID: String, socketManager: WebSocketManager, remote: RemoteInterface) {
        self.currentUserID = currentUserID
        self.webSocketManager = socketManager
        self.remote = remote
        
        /*
         This might be the time to use vanila notifications, not signals?
         */
        
        // observe web socket
        socketManager.onConnected.subscribe(with: self) { _ in
            self.didConnect()
        }
        socketManager.onDisconnected.subscribe(with: self) { _ in
            self.didDisconnect()
        }
        socketManager.onInventoryUpdate.subscribe(with: self) { inventoryEvent in
            self.didReceiveInventoryUpdate(inventoryEvent)
        }
        BLOCKv.socket.onVatomStateUpdate.subscribe(with: self) { stateUpdateEvent in
            self.didReceiveStateUpdate(stateUpdateEvent)
        }
        
    }
    
//    func socketMessage() -> RemoteRecordChange<VatomModel> {
//
//    }
    
    // MARK: - SocketNotificationDrain
    
    func didConnect() {
        print(#function)
    }
    
    func didDisconnect() {
        print(#function)
    }
    
    /// Called when an inventory-event is received.
    func didReceiveInventoryUpdate(_ inventoryUpdate: WSInventoryEvent) {
        print(#function)
        
        if inventoryUpdate.didAddVatomToInventory(ofUser: self.currentUserID) {
            
            // pause socket processing until the vatom has been retrieved
            self.isPaused = true
            let workItem = DispatchWorkItem {
                // fetch remote vatom
                
                /*
                 FIXME
                 Is this the right pattern? The completion hanlder get asked to complete on the serial queue.
                 Should this apply to all sync operations which occur in the sync framework?
                 */
                
                self.remote.getVatom(withID: inventoryUpdate.vatomId, queue: self.serialQueue) { result in
                    
                    let vatomModel = try! result.get()
                    let change = RemoteRecordChange<VatomModel>.insert(vatomModel)
                    self.isPaused = false
                    //TODO: broadcast change
                }
            }
            serialQueue.async { workItem }
            
        } else if inventoryUpdate.didRemoveVatomFromInventory(ofUser: self.currentUserID) {
            
            let workItem = DispatchWorkItem {
                let change = RemoteRecordChange<VatomModel>.delete(inventoryUpdate.vatomId)
                //TODO: broadcast change
            }
            serialQueue.async { workItem }

        } else {
            fatalError("Locic error")
        }
    }

    /// Called when a state-update-event is received.
    func didReceiveStateUpdate(_ stateUpdate: WSStateUpdateEvent) {
        print(#function)
        
        let workItem = DispatchWorkItem {
            let change = RemoteRecordChange<VatomModel>.partialUpdate(stateUpdate)
            //TODO: broadcast change
        }
        serialQueue.async { workItem }

    }
    
}
