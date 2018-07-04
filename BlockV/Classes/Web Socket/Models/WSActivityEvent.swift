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
    "msg_id": 1529607790858154200,
    "vatoms": [
      "2c2057ef-6ba2-4b89-8ff6-238c670b1b8a"
    ],
    "action_name": "Transfer",
    "triggered_by": "2e1038f8-ffcd-4e91-aa81-ccfc74ae9d79",
    "msg": "<b>ydangle vAtomic</b> sent you a <b>Converse Sneaker</b> vAtom.",
    "user_id": "afd0c5a1-8bd9-4371-bfa6-134d357b9800",
    "when_created": "2018-06-21T19:03:10Z",
    "generic": [
      {
        "name": "ActivatedImage",
        "value": {
          "value": "https://cdndev.blockv.net/vatomic.prototyping/redsneaker_card.jpg",
          "resourceValueType": "ResourceValueType::URI"
        },
        "resourceType": "ResourceTypes::Image::JPEG"
      }
    ]
  },
  "user_id": "afd0c5a1-8bd9-4371-bfa6-134d357b9800"
}
*/

/// Web socket response model - Inventory Event.
public struct WSActivityEvent: WSEvent, Equatable {

    // MARK: - Properties

    /// Unique identifier of the activity event.
    public let eventId: Int
    /// Unique identifier of the user this event is targetted for.
    ///
    /// Typically, this is the current user.
    public let targetUserId: String
    /// Unique identifier of the user triggering this event.
    public let triggerUserId: String
    /// Array of vAtoms associated with this event.
    public let vatomIds: [String]
    /// Array of ActivateImage resources.
    ///
    /// For each associated vAtom, there may be zero or one ActivatedImage resources.
    public let resources: [VatomResourceModel]
    /// The user-facing contents of the event.
    public let message: String
    /// Name of the action which triggered this event.
    public let actionName: String
    /// Timestamp of this event's creation.
    public let whenCreated: Date

    // Client-side

    /// Timestamp of when the event was received on-device (client-side).
    let timestamp: Date

}

extension WSActivityEvent: Decodable {

    enum CodingKeys: String, CodingKey {
        case payload
    }

    enum PayloadCodingKeys: String, CodingKey {
        case eventId         = "msg_id"
        case targetUserId    = "user_id"
        case triggerUserId   = "triggered_by"
        case vatomIds        = "vatoms"
        case message         = "msg"
        case actionName      = "action_name"
        case whenCreated     = "when_created"
        case generic         = "generic"
    }

    public init(from decoder: Decoder) throws {

        let items = try decoder.container(keyedBy: CodingKeys.self)
        // de-nest payload to top level
        let payloadContainer = try items.nestedContainer(keyedBy: PayloadCodingKeys.self, forKey: .payload)
        eventId       = try payloadContainer.decode(Int.self, forKey: .eventId)
        targetUserId  = try payloadContainer.decode(String.self, forKey: .targetUserId)
        triggerUserId = try payloadContainer.decode(String.self, forKey: .triggerUserId)
        vatomIds      = try payloadContainer.decode([String].self, forKey: .vatomIds)
        resources     = try payloadContainer.decodeIfPresent([VatomResourceModel].self, forKey: .generic) ?? []
        message       = try payloadContainer.decode(String.self, forKey: .message)
        actionName    = try payloadContainer.decode(String.self, forKey: .actionName)
        whenCreated   = try payloadContainer.decode(Date.self, forKey: .whenCreated)

        // stamp this event with the current time
        timestamp = Date()

    }

}
