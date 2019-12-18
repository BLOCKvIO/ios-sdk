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

/// Unit Tests for Activty model Codable conformances.
///
/// Tested models:
/// - `ThreadModel`
/// - `MessageModel`
/// - `ThreadListModel`
/// - `MessageListModel`
class ActivityModelCodable_Tests: XCTestCase {

    /// Test Codable transformations of an Activity Thread.
    func testActivityThreadCodable() {

        self.decodeEncodeCompare(type: ThreadModel.self,
                                 from: MockModel2.activityThreadServerResponse_V1)

    }

    /// Test Codable transformations of an Activity Message.
    func testActivityMessageCodable() {

        self.decodeEncodeCompare(type: MessageModel.self,
                                 from: MockModel2.activityMessageServerResponse_V1)

    }

    /// Test Codable transformations of Activity Thread List.
    func testActivityThreadListCodable() {

        self.decodeEncodeCompare(type: BaseModelTest<ThreadListModel>.self,
                                 from: MockModel2.activityThreadListServerResponse_V1)

    }

    /// Test Codable transformations of an Activity Message.
    func testActivityMessageListCodable() {

        self.decodeEncodeCompare(type: BaseModelTest<MessageListModel>.self,
                                 from: MockModel2.activityMessageListServerResponse_V1)

    }

}
