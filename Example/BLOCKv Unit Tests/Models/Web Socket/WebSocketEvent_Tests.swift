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

class WebSocketEvent_Tests: XCTestCase {

    func testMapEventDecoding() {

        do {
            _ = try TestUtility.jsonDecoder.decode(WSMapEvent.self, from: MockWebSocket.mapEvent)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }

    }

}
