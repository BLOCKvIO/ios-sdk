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

/// Protocol representing a Web socket event.
protocol WSEvent: Decodable {
    
    /// Timestamp of when the event was received on-device (client-side).
    var timestamp: Date { get }
    
}



// Start turning the Web Socket into proper models.

//public struct WSBaseModel<T: Decodable> {
//    
//    /// Models the type of events sent over the Web socket.
//    enum WSMessageType: String {
//        case inventory   = "inventory"
//        case stateUpdate = "state_update"
//        case myEvents    = "my_events"
//    }
//    
//    let type: String
//    let payload: T //FIXME: How to handle a raw payload (since T must conform to Codable).
//    
//    init(_ payload: T) {
//        self.payload = payload
//    }
//    
//}

//extension WSBaseModel: Codable {
//    
//    enum CodingKeys: String, CodingKey {
//        case type = "msg_type"
//        case payload
//    }
//    
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        type = try container.decode(String.self, forKey: .type)
//        
//        // construct the enum of known events
//        switch WSMessageType(rawValue: type) {
//        case .some(let event):
//            switch event {
//            case .inventory:
//                print("Inventory")
//                payload = try! container.decode(WSInventoryEvent.self, forKey: .payload)
//            case .stateUpdate:
//                print("State Update")
//            case .myEvents:
//                print("My Events")
//            }
//        default:
//            printBV(error: "Unknown Web socket event type.")
//            
//            payload = try container.decodeIfPresent(JSON.self, forKey: .payload)!
//        }
//        
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
////        try container.encode(code, forKey: .code)
////        try container.encode(message, forKey: .message)
//    }
//    
//}

