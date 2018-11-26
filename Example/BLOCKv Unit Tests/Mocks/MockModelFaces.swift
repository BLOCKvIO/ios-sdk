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

public struct MockModelFaces {
    
    
    /// Two native generic faces, one icon and one 3d.
    public static let genericIconAnd3D = """
        [
          {
            "id": "aaaa",
            "template": "vatomic.prototyping::UntiTest::v1",
            "meta": {
              "created_by": "BLOCKv Backend",
              "when_created": "2018-08-14T12:16:05Z",
              "modified_by": "",
              "when_modified": "2018-08-14T12:16:05Z",
              "data_type": "v1::FaceType",
              "in_sync": false,
              "when_synced": "",
              "is_syncing": false
            },
            "properties": {
              "display_url": "native://image",
              "package_url": "native://image",
              "constraints": {
                "bluetooth_le": false,
                "contact_list": false,
                "gps": false,
                "three_d": false,
                "view_mode": "card",
                "platform": "generic",
                "quality": "high"
              },
              "resources": [
                "CardImage"
              ],
              "config": {
                "image": "CardImage"
              }
            }
          },
          {
            "id": "bbbb",
            "template": "vatomic.prototyping::UntiTest::v1",
            "meta": {
              "created_by": "BLOCKv Backend",
              "when_created": "2018-08-14T12:16:04Z",
              "modified_by": "",
              "when_modified": "2018-08-14T12:16:04Z",
              "data_type": "v1::FaceType",
              "in_sync": false,
              "when_synced": "",
              "is_syncing": false
            },
            "properties": {
              "display_url": "native://generic-3d",
              "package_url": ".",
              "constraints": {
                "bluetooth_le": false,
                "contact_list": false,
                "gps": false,
                "three_d": false,
                "view_mode": "icon",
                "platform": "generic",
                "quality": "low"
              },
              "resources": []
            }
          }
        ]
        """.data(using: .utf8)!
    
    
    /// Same as above but with array ordering reveresed.
    let genericIconAnd3DOrderRevered = """
        [
          {
            "id": "bbbb",
            "template": "vatomic.prototyping::UntiTest::v1",
            "meta": {
              "created_by": "BLOCKv Backend",
              "when_created": "2018-08-14T12:16:04Z",
              "modified_by": "",
              "when_modified": "2018-08-14T12:16:04Z",
              "data_type": "v1::FaceType",
              "in_sync": false,
              "when_synced": "",
              "is_syncing": false
            },
            "properties": {
              "display_url": "native://generic-3d",
              "package_url": ".",
              "constraints": {
                "bluetooth_le": false,
                "contact_list": false,
                "gps": false,
                "three_d": false,
                "view_mode": "icon",
                "platform": "generic",
                "quality": "low"
              },
              "resources": []
            }
          },
          {
            "id": "aaaa",
            "template": "vatomic.prototyping::UntiTest::v1",
            "meta": {
              "created_by": "BLOCKv Backend",
              "when_created": "2018-08-14T12:16:05Z",
              "modified_by": "",
              "when_modified": "2018-08-14T12:16:05Z",
              "data_type": "v1::FaceType",
              "in_sync": false,
              "when_synced": "",
              "is_syncing": false
            },
            "properties": {
              "display_url": "native://image",
              "package_url": "native://image",
              "constraints": {
                "bluetooth_le": false,
                "contact_list": false,
                "gps": false,
                "three_d": false,
                "view_mode": "card",
                "platform": "generic",
                "quality": "high"
              },
              "resources": [
                "CardImage"
              ],
              "config": {
                "image": "CardImage"
              }
            }
          }
        ]
        """.data(using: .utf8)!
    
}
