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
import MapKit

/// Web socket event model - unowned map vatoms.
public struct WSMapEvent: Decodable {

    // MARK: - Properties

    /// Unique identifier of this inventory event.
    public let eventId: String
    /// Database operation.
    public let operation: String
    /// Unique identifier of the vAtom which generated this event.
    public let vatomId: String
    /// Action name.
    public let actionName: String
    /// Coordinate of event.
    public let coordinate: CLLocationCoordinate2D

    enum CodingKeys: String, CodingKey {
        case payload
    }

    enum PayloadCodingKeys: String, CodingKey {
        case eventId             = "event_id"
        case operation           = "op"
        case vatomId             = "vatom_id"
        case actionName          = "action_name"
        case latitude            = "lat"
        case longitude           = "lon"
    }

    public init(from decoder: Decoder) throws {

        let items = try decoder.container(keyedBy: CodingKeys.self)
        // de-nest payload to top level
        let payloadContainer = try items.nestedContainer(keyedBy: PayloadCodingKeys.self, forKey: .payload)
        // de-nest payload to top level
        eventId         = try payloadContainer.decode(String.self, forKey: .eventId)
        operation       = try payloadContainer.decode(String.self, forKey: .operation)
        vatomId         = try payloadContainer.decode(String.self, forKey: .vatomId)
        actionName      = try payloadContainer.decode(String.self, forKey: .actionName)
        let latitude    = try payloadContainer.decode(Double.self, forKey: .latitude)
        let longitude   = try payloadContainer.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

}
