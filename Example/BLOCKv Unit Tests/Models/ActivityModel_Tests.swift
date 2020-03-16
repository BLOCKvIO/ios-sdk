//
//  BLOCKv AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BLOCKv SDK License (the "License"); you may not use this file or
//  the BLOCKv SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BLOCKv SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import XCTest
@testable import BLOCKv

// MARK: - Mock Server Data

private let resourcesModelData = """
[
  {
    "name": "ActivatedImage",
    "resourceType": "ResourceTypes::Image::JPEG",
    "value": {
      "resourceValueType": "ResourceValueType::URI",
      "value": "https://eg.blockv.io/vatomic.prototyping/asdf/some.gif"
    }
  }
]
""".data(using: .utf8)!

private let activityMessageData = """
{
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
        "value": "https://eg.blockv.io/vatomic.prototyping/asdf/some.gif"
      }
    }
  ]
}
""".data(using: .utf8)!

// MARK: - Control Model

// create resources to be used in `messageControl`
private let resourcesControl = try! TestUtility.jsonDecoder.decode([VatomResourceModel].self, from: resourcesModelData)
private let whenCreatedControl = DateFormatter.blockvDateFormatter.date(from: "2019-06-08T10:17:20Z")!
// construct a model manually to act as the control
private let messageControl = MessageModel.init(id: 1234,
                                               message: "<b>ydangle Prototyping</b> sent you a <b>Pepsi</b> vAtom.",
                                               actionName: "Transfer",
                                               whenCreated: whenCreatedControl,
                                               triggerUserID: "12348f8-ffcd-4e91-aa81-ccfc74ae1234",
                                               targetUserID: "21c527fb-1234-485b-b549-61b3857e1234",
                                               vatomIdentifiers: ["1234781-139c-48e3-b311-e177af61234"],
                                               templateVariationIdentifiers: [],
                                               resources: resourcesControl,
                                               geoPosition: nil)

class ActivityModel_Tests: XCTestCase {

    // MARK: - Test Methods

    /// Tests the decoding of server data to a native message model.
    /// Tests the decoded model matches a manually created model.
    func testMessageModelDecoding() {

        do {
            // ensure model is parsed
            let value = try TestUtility.jsonDecoder.decode(MessageModel.self, from: activityMessageData)
            let model = try self.require(value)
            // ensure model matches control
            XCTAssertEqual(model, messageControl)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }

    }

    func testMessageModelCodable() {
        self.decodeEncodeCompare(type: MessageModel.self, from: activityMessageData)
    }

}
