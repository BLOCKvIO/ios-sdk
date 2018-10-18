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

class VatomModelUpdate_Tests: XCTestCase {
    
    // FIXME: Don't force unwrap
    let vatom = try! TestUtility.jsonDecoder.decode(VatomModel.self, from: MockModel.VatomModel.stateUpdateVatom)

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRootPropertyUpdate() {
        
        let properties: JSON =  [
            "vAtom::vAtomType": [
                ["num_direct_clones" : 3]
            ]
        ]
        
        let mockStateUpdate = WSStateUpdateEvent(eventId: "1",
                                                 operation: "mock",
                                                 vatomId: "1234",
                                                 vatomProperties: properties,
                                                 timestamp: Date())
        
    }
    
    func testPrivatePropertyUpdate() {
        
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
