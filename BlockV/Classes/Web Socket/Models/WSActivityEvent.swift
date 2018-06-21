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
 {
  "msg_type": "my_events",
  "payload": {
    "msg_id": 1527143531875652000,
    "user_id": "0f1a7a8b-bcce-4594-8ed5-64cd7d374235",
    "vatoms": [
      "7ce99327-ceb8-4eb5-8482-71275b3b770a"
    ],
    "msg": "<b>vAtomic Systems</b> sent you a <b>Heineken Crate</b> vAtom.",
    "action_name": "Transfer",
    "when_created": "2018-05-24T06:32:11Z",
    "triggered_by": "2e1038f8-ffcd-4e91-aa81-ccfc74ae9d79",
    "generic": [
      {
        "name": "ActivatedImage",
        "resourceType": "ResourceTypes::Image::PNG",
        "value": {
          "resourceValueType": "ResourceValueType::URI",
          "value": "https:cdn.blockv.io/templates/vatomic.prototyping/AnimatedCrate/v1/HeinekenCrate/v2/ActivatedImage.png"
        }
      }
    ]
  }
}
*/

/// Web socket response model - Inventory Event.
public struct WSActivityEvent: WSEvent, Equatable {
    
    // MARK: - Properties
    
    /// Timestamp of when the event was received on-device (client-side).
    let timestamp: Date
    
    /// Unique identifier of the message.
    let messageId: Int
    ///
    let userId: String
    ///
    let triggerByUserId: String
    ///
    let vatomIds: [String]
    /// The contents of the message event.
    let message: String
    /// Name of the action which triggered the activity message.
    let actionName: String
    /// Timestamp of this event's creation.
    let whenCreated: Date
    
    // generic
    
}

extension WSActivityEvent: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case payload = "payload"
    }
    
    enum PayloadCodingKeys: String, CodingKey {
        case messageId       = "msg_id"
        case userId          = "user_id"
        case vatomIds        = "vatoms"
        case message         = "msg"
        case actionName      = "action_name"
        case whenCreated     = "when_created"
        case triggerByUserId = "triggered_by"
    }
    
    public init(from decoder: Decoder) throws {
        
        let items = try decoder.container(keyedBy: CodingKeys.self)
        // de-nest payload to top level
        let payloadContainer = try items.nestedContainer(keyedBy: PayloadCodingKeys.self, forKey: .payload)
        messageId            = try payloadContainer.decode(Int.self, forKey: .messageId)
        userId               = try payloadContainer.decode(String.self, forKey: .userId)
        vatomIds             = try payloadContainer.decode([String].self, forKey: .vatomIds)
        message              = try payloadContainer.decode(String.self, forKey: .message)
        actionName           = try payloadContainer.decode(String.self, forKey: .actionName)
        whenCreated          = try payloadContainer.decode(Date.self, forKey: .whenCreated)
        triggerByUserId      = try payloadContainer.decode(String.self, forKey: .triggerByUserId)
        
        // stamp this event with the current time
        timestamp = Date()
        
    }

}
