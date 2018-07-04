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
  "msg_type": "inventory",
  "payload": {
    "event_id": "inv_7ce99327-ceb8-4eb5-8482-71275b3b770a:2018-05-24T06:32:11Z",
    "op": "insert",
    "id": "7ce99327-ceb8-4eb5-8482-71275b3b770a",
    "new_owner": "0f1a7a8b-bcce-4594-8ed5-64cd7d374235",
    "old_owner": "2e1038f8-ffcd-4e91-aa81-ccfc74ae9d79",
    "template_variation": "vatomic.prototyping::AnimatedCrate::v1::HeinekenCrate::v2",
    "parent_id": "."
  }
}
*/

/// Web socket response model - Inventory Event.
public struct WSInventoryEvent: WSEvent, Equatable {

    // MARK: - Properties

    /// Unique identifier of this inventory event.
    public let eventId: String
    /// Database operation.
    public let operation: String
    /// Unique identifier of the vAtom which generated this event.
    public let vatomId: String
    /// Unique identifier of the new owner of the vAtom.
    public let newOwnerId: String
    /// Unique identifier of the old owner of the vAtom
    public let oldOwnerId: String
    /// Unique identifier of the temlate variation of the vAtom.
    public let templateVariationId: String
    /// Unique identifier of the vAtom's parent.
    /// "." indicates the vAtom is at the root level.
    public let parentId: String

    // Client-side

    /// Timestamp of when this event was received (client-side).
    let timestamp: Date

    // MARK: - Helpers

    /*
     Note: Still deciding if these helpers should be public API. Maybe an enum .added or .removed
     is simpler?
     */

    /// Boolean indicating whether, accoring to this event, the vatom was added to
    /// the inventory of the specified user.
    ///
    /// Returns `true` only if there was an ownership change involving the supplied
    /// user.
    func didAddVatomToInventory(ofUser comparisonUserId: String) -> Bool {
        return (newOwnerId == comparisonUserId) && (oldOwnerId != comparisonUserId)
    }

    /// Boolean indicating whether, accoring to this event, the vatom was removed
    /// from the inventory of the specified user.
    ///
    /// Returns `true` only if there was an ownership change involving the supplied
    /// user.
    func didRemoveVatomFromInventory(ofUser comparisonUserId: String) -> Bool {
        return (oldOwnerId == comparisonUserId) && (newOwnerId != comparisonUserId)
    }

}

extension WSInventoryEvent: Decodable {

    // discard the outer payload - we are only interesting in the payload data
    enum CodingKeys: String, CodingKey {
        case payload
    }

    enum PayloadCodingKeys: String, CodingKey {
        case eventId             = "event_id"
        case operation           = "op"
        case vatomId             = "id"
        case newOwnerId          = "new_owner"
        case oldOwnerId          = "old_owner"
        case templateVariationId = "template_variation"
        case parentId            = "parent_id"
    }

    public init(from decoder: Decoder) throws {

        let items = try decoder.container(keyedBy: CodingKeys.self)
        // de-nest payload to top level
        let payloadContainer = try items.nestedContainer(keyedBy: PayloadCodingKeys.self, forKey: .payload)
        eventId             = try payloadContainer.decode(String.self, forKey: .eventId)
        operation           = try payloadContainer.decode(String.self, forKey: .operation)
        vatomId             = try payloadContainer.decode(String.self, forKey: .vatomId)
        newOwnerId          = try payloadContainer.decode(String.self, forKey: .newOwnerId)
        oldOwnerId          = try payloadContainer.decode(String.self, forKey: .oldOwnerId)
        templateVariationId = try payloadContainer.decode(String.self, forKey: .templateVariationId)
        parentId            = try payloadContainer.decode(String.self, forKey: .parentId)

        // stamp this event with the current time
        timestamp = Date()

    }

}
