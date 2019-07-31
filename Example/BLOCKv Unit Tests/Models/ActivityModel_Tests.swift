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

import XCTest
@testable import BLOCKv

private let activityMessageModel = """
{
  "message": {
    "msg_id": 1234,
    "user_id": "21c527fb-1234-485b-b549-61b3857e1234",
    "vatoms": [
      "1234781-139c-48e3-b311-e177af61234"
    ],
    "msg": "<b>ydangle Prototyping</b> sent you a <b>Pepsi</b> vAtom.",
    "action_name": "Transfer",
    "when_created": "2019-06-08T10:17:20Z",
    "triggered_by": "12348f8-ffcd-4e91-aa81-ccfc74ae1234",
    "generic": [
      {
        "name": "ActivatedImage",
        "resourceType": "ResourceTypes::Image::JPEG",
        "value": {
          "resourceValueType": "ResourceValueType::URI",
          "value": "https://eg.blockv.io/vatomic.prototyping/vatomic.prototyping::v1::MultiLevelViral/some.gif"
        }
      }
    ]
  },
  "when_modified": 1559989040761331324
}
""".data(using: .utf8)!

class ActivityModel_Tests: XCTestCase {

    // MARK: - Test Methods
    
    func testMessageModelDecoding() {
        
        do {
            let value = try TestUtility.jsonDecoder.decode(MessageModel.self, from: activityMessageModel)
            let model = try self.require(value)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
    }
    
    func testMessageModelCodable() {
        self.decodeEncodeCompare(type: MessageModel.self, from: activityMessageModel)
    }

}
