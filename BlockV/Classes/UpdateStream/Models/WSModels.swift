//
//  WSModels.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/05/24.
//

import Foundation

// Start turning the Web Socket into proper models.

struct WSBaseModel<T: Codable>: Codable {
    let type: String
    let payload: T
}

// MARK: - Inventory

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

struct WSInventoryModel: Codable {
    
    let eventID: String
    let id: String
    let newOwnerId: String
    let oldOwnerId: String
    let templateVariationID: String
    let parentID: String
    
}

// MARK: - My Events

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

struct WSMyEvent: Codable {
    
    
    
}
