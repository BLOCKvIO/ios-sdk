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

/// Represents a message.
public struct MessageModel: Equatable {
    
    /// Unique identifier of the message.
    public let id: Double
    /// Message content
    public let message: String
    /// Common name of the action which triggered the message.
    ///
    /// - **User Message** - Indicates a text message exchange.
    public let actionName: String
    /// Timestamp of when the message was created.
    public let whenCreated: Date
    /// Timestamp of then the message was modified.
    //public let whenModified: Date
    
    // - Users
    
    ///
    public let triggeredBy: String
    ///
    public let userId: String
    
    // - Auxillary
    
    /// Array of associated vAtom identifiers.
    public let vatomIds: [String]
    /// Array of templated variation identifiers (for each associated vAtom).
    public let templateVariationIds: [String]
    /// Array of resources (for each associated vAtom).
    public let resources: [VatomResource]
    ///
    public let geoPosition: [Double]? //FIXME: Convert to CLLocationCoordinate2D?
    
    enum CodingKeys: String, CodingKey {
        case id                   = "msg_id"
        case userId               = "user_id"
        case vatomIds             = "vatoms"
        case templateVariationIds = "templ_vars"
        case message              = "msg"
        case actionName           = "action_name"
        case whenCreated          = "when_created"
        case triggeredBy          = "triggered_by"
        case resources            = "generic"
        case geoPosition          = "geo_pos"
    }
    
}

extension MessageModel: Codable {

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id                   = try container.decode(Double.self, forKey: .id)
        userId               = try container.decode(String.self, forKey: .userId)
        message              = try container.decode(String.self, forKey: .message)
        actionName           = try container.decode(String.self, forKey: .actionName)
        whenCreated          = try container.decode(Date.self, forKey: .whenCreated)
        triggeredBy          = try container.decode(String.self, forKey: .triggeredBy)
        
        // potentially `null`
        geoPosition          = try container.decodeIfPresent([Double].self, forKey: .geoPosition)
        templateVariationIds = try container.decodeIfPresent([String].self, forKey: .templateVariationIds) ?? []
        vatomIds             = try container.decodeIfPresent([String].self, forKey: .vatomIds) ?? []
        resources            = container.decodeSafelyIfPresentArray(of: VatomResource.self, forKey: .resources)

    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(message, forKey: .message)
        try container.encode(actionName, forKey: .actionName)
        try container.encode(whenCreated, forKey: .whenCreated)
        try container.encode(triggeredBy, forKey: .triggeredBy)
        try container.encode(templateVariationIds, forKey: .templateVariationIds)
        try container.encode(vatomIds, forKey: .vatomIds)
        try container.encode(resources, forKey: .resources)
        
        try container.encodeIfPresent(geoPosition, forKey: .geoPosition)

    }

}
