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

/*
 - Drop
 {
  "msg_type": "state_update",
  "payload": {
    "op": "update",
    "id": "3c9d9dc2-9c75-4727-ad0e-392cb53caae1",
    "new_object": {
      "vAtom::vAtomType": {
        "parent_id": ".",
        "visibility": {
          "type": "public",
          "value": "*"
        },
        "geo_pos": {
          "type": "Point",
          "coordinates": [
            18.47328211186288,
            -33.95786432820779
          ],
          "$reql_type$": "GEOMETRY"
        },
        "dropped": true
      },
      "when_modified": "2018-06-21T20:36:00Z"
    },
    "event_id": "state_3c9d9dc2-9c75-4727-ad0e-392cb53caae1:2018-06-21T20:36:00Z"
  },
  "user_id": "afd0c5a1-8bd9-4371-bfa6-134d357b9800"
}
 
 - Pick Up
 {
  "msg_type": "state_update",
  "payload": {
    "op": "update",
    "id": "3c9d9dc2-9c75-4727-ad0e-392cb53caae1",
    "new_object": {
      "vAtom::vAtomType": {
        "dropped": false,
        "owner": "afd0c5a1-8bd9-4371-bfa6-134d357b9800",
        "visibility": {
          "type": "owner",
          "value": "*"
        }
      },
      "when_modified": "2018-06-21T20:33:27Z"
    },
    "event_id": "state_3c9d9dc2-9c75-4727-ad0e-392cb53caae1:2018-06-21T20:33:27Z"
  },
  "user_id": "afd0c5a1-8bd9-4371-bfa6-134d357b9800"
}
*/

/// Web socket response model - Inventory Event.
public struct WSStateUpdateEvent: WSEvent {
    
    // MARK: - Properties
    /// Unique identifier of this state update event.
    public let eventId: String
    /// Database operation.
    public let operation: String
    /// Unique identifier of the vAtom which generated this event.
    public let vatomId: String
    /// JSON object containing the only updated properties of the vAtom.
    //public let vatomProperties: JSON
    /// JSON object containing the only updated properties of the vAtom.
    public let vatomProperties: [String : Any] // Forces manual Equatable conformance
    /// Timestamp of when the vAtom was modified.
    public let whenModified: Date
    
    // Client-side

    /// Timestamp of when the event was received (client-side).
    let timestamp: Date

}

/*
 Decodable does not play nice because of the 'flexible' payload of the state update...
 */
extension WSStateUpdateEvent: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case payload = "payload"
    }
    
    enum PayloadCodingKeys: String, CodingKey {
        case eventId   = "event_id"
        case operation = "op"
        case vatomId   = "id"
        case newObject = "new_object"
    }
    
    enum NewObjectCodingKeys: String, CodingKey {
        case vatomProperties = "vAtom::vAtomType"
        case whenModified    = "when_modified"
    }
    
    public init(from decoder: Decoder) throws {
        
        let items = try decoder.container(keyedBy: CodingKeys.self)
        // de-nest payload to top level
        let payloadContainer = try items.nestedContainer(keyedBy: PayloadCodingKeys.self, forKey: .payload)
        eventId       = try payloadContainer.decode(String.self, forKey: .eventId)
        operation     = try payloadContainer.decode(String.self, forKey: .operation)
        vatomId       = try payloadContainer.decode(String.self, forKey: .vatomId)
        
        let newObjectContainer = try payloadContainer.nestedContainer(keyedBy: NewObjectCodingKeys.self, forKey: .newObject)
        //vatomProperties = try newObjectContainer.decode(JSON.self, forKey: .vatomProperties)
        vatomProperties = [:]
        whenModified    = try newObjectContainer.decode(Date.self, forKey: .whenModified)
        
        // stamp this event with the current time
        timestamp = Date()
        
    }
    
}

extension WSStateUpdateEvent {
    
    public init(form dictionary: [String : Any]) throws {
        
        guard
            let payload = dictionary["payload"] as? [String : Any],
            let eventId = payload["event_id"] as? String,
            let operation = payload["op"] as? String,
            let vatomID = payload["id"] as? String,
            let newObject = payload["new_object"] as? [String : Any],
            let vatomProperties = newObject["vAtom::vAtomType"] as? [String : Any],
            let whenModifiedString = newObject["when_modified"] as? String else {
                printBV(error: "Model decoding failed.")
                throw BVJSONError.decodingError //FIXME: Throw proper error
        }
        
        self.eventId = eventId
        self.operation = operation
        self.vatomId = vatomID
        self.vatomProperties = vatomProperties
        guard let whenModifiedDate = DateFormatter.blockvDateFormatter.date(from: whenModifiedString) else {
            printBV(error: "Model decoding failed.")
            throw BVJSONError.decodingError //FIXME: Throw proper error
        }
        self.whenModified = whenModifiedDate
        
        // stamp this event with the current time
        timestamp = Date()
    }
    
}

extension WSStateUpdateEvent: Equatable { }

public func ==(lhs: WSStateUpdateEvent, rhs: WSStateUpdateEvent) -> Bool {
    return lhs.eventId == rhs.eventId
}
