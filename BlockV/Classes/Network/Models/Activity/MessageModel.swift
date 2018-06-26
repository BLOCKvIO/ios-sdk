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
public struct MessageModel {
    
    /// Unique identifier of the message.
    public let id: String
    /// Message content
    public let message: String
    /// Common name of the action which triggered the message.
    ///
    /// - **User Message** - Indicates a text message exchange.
    public let actionName: String
    /// Timestamp of when the message was created.
    public let whenCreated: Date
    /// Timestamp of when the message was modified.
    public let whenModifed: Date
    
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
        case message      = "message"
        case whenModified = "when_modified"
    }
    
    enum MessageCodingKeys: String, CodingKey {
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
        whenModifed = try container.decode(Date.self, forKey: .whenModified)
        
        // de-nest properties to top level
        let messageContainer = try container.nestedContainer(keyedBy: MessageCodingKeys.self, forKey: .message)
        id                   = try messageContainer.decode(String.self, forKey: .id)
        userId               = try messageContainer.decode(String.self, forKey: .userId)
        message              = try messageContainer.decode(String.self, forKey: .message)
        actionName           = try messageContainer.decode(String.self, forKey: .actionName)
        whenCreated          = try messageContainer.decode(Date.self, forKey: .whenCreated)
        triggeredBy          = try messageContainer.decode(String.self, forKey: .triggeredBy)
        
        // potentially `null`
        geoPosition          = try messageContainer.decodeIfPresent([Double].self, forKey: .geoPosition)
        templateVariationIds = try messageContainer.decodeIfPresent([String].self, forKey: .templateVariationIds) ?? []
        vatomIds             = try messageContainer.decodeIfPresent([String].self, forKey: .vatomIds) ?? []
        resources            = try messageContainer.decodeIfPresent([VatomResource].self, forKey: .resources) ?? []

    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }

}

let message1 = """
    {
        "message": {
            "msg_id": 1522251946067536131,
            "user_id": "bb162d66-bfef-401e-ad89-3edf8388e01c",
            "vatoms": [],
            "templ_vars": null,
            "msg": "hey man",
            "action_name": "User Message",
            "when_created": "2018-03-28T15:45:46Z",
            "triggered_by": "b9e6581c-bb70-48d1-85eb-6657ee1a3bef",
            "generic": null,
            "geo_pos": null,
            "to_data_lake": false,
            "no_message": false
        },
        "when_modified": 1522251946067536128
    }
    """.data(using: .utf8)!

let message2 = """
    {
        "message": {
            "msg_id": 1522250650907474423,
            "user_id": "bb162d66-bfef-401e-ad89-3edf8388e01c",
            "vatoms": [
                "2ef141aa-1b91-4576-a7d0-a5db791a5da0"
            ],
            "templ_vars": null,
            "msg": "<b>test van duffelen</b> sent you a <b>Drink Menu</b> vAtom.",
            "action_name": "Transfer",
            "when_created": "2018-03-28T15:24:10Z",
            "triggered_by": "b9e6581c-bb70-48d1-85eb-6657ee1a3bef",
            "generic": [
                {
                    "name": "ActivatedImage",
                    "resourceType": "ResourceTypes::Image::PNG",
                    "value": {
                        "resourceValueType": "ResourceValueType::URI",
                        "value": "https://cdndev.blockv.net/vatomic.prototyping/MenuCard/v2/Harvelles/v1/harvelles_menu_icon.png"
                    }
                }
            ],
            "geo_pos": null,
            "to_data_lake": false,
            "no_message": false
        },
        "when_modified": 1522250650907474432
    }
    """.data(using: .utf8)!


var test: MessageModel = {
   
    do {
        let jsonDecoder = JSONDecoder()
        let a = try jsonDecoder.decode(MessageModel.self, from: message1)
        print(a)
        let b = try jsonDecoder.decode(MessageModel.self, from: message2)
        print(b)
    } catch {
        print(error)
    }
    
}()


