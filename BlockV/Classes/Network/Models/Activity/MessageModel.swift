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
    
    /// Array of associated vAtoms.
    public let vatoms: [Vatom]
    /// Array of templated variation identifiers (for each associated vAtom).
    public let templateVariationIds: [String]
    /// Array of resources (for each associated vAtom).
    public let resources: [VatomResource]
    ///
    public let geoPosition: [Double]
    
    enum CodingKeys: String, CodingKey {
        case message      = "message"
        case whenModified = "when_modified"
    }
    
    enum MessageCodingKeys: String, CodingKey {
        case id                   = "msg_id"
        case userId               = "user_id"
        case vatoms               = "vatoms"
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
   
    let jsonDecoder = JSONDecoder()
    jsonDecoder.da
    
}()


