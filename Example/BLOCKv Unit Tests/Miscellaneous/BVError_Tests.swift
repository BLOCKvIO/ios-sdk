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

class BVError_Tests: XCTestCase {
    
    // MARK: - Lifcycle
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testInterErrorEquatable() {
        
        // Top level
        
        let errorPlatform = BVError.platform(reason: .authenticationLimit(0, "test"))
        let errorWebSocket = BVError.webSocket(error: .connectionFailed)
        let errorModelDecoding = BVError.modelDecoding(reason: "test")
        
        XCTAssertNotEqual(errorPlatform, errorWebSocket)
        XCTAssertNotEqual(errorPlatform, errorModelDecoding)

    }
    
    func testPlatformErrorEquatable() {
        
        // Top level
        
        let errorA = BVError.platform(reason: .authenticationFailed(0, "test"))
        let errorB = BVError.platform(reason: .authenticationFailed(0, "test"))
        let errorC = BVError.platform(reason: .cannotDeletePrimaryToken(0, "test"))
        
        XCTAssertEqual(errorA, errorB)
        XCTAssertNotEqual(errorA, errorC)

        // Reason
        
        let errorReasonA = BVError.PlatformErrorReason(code: 100, message: "Some test error message.")
        let errorReasonB = BVError.PlatformErrorReason(code: 100, message: "Some test error message.")
        let errorReasonC = BVError.PlatformErrorReason(code: 100, message: "Some different test error message")
        let errorReasonD = BVError.PlatformErrorReason(code: 200, message: "Some test error message.")
        
        XCTAssertEqual(errorReasonA, errorReasonA)
        XCTAssertEqual(errorReasonA, errorReasonB)
        XCTAssertNotEqual(errorReasonA, errorReasonC)
        XCTAssertNotEqual(errorReasonA, errorReasonD)
        
    }
    
    func testWebSocketErrorEquatable() {
        
        // Top level
        
        let errorA = BVError.webSocket(error: .connectionDisconnected)
        let errorB = BVError.webSocket(error: .connectionDisconnected)
        let errorC = BVError.webSocket(error: .connectionFailed)
        
        XCTAssertEqual(errorA, errorB)
        XCTAssertNotEqual(errorA, errorC)
        
        // Reason
    
        let errorReasonA = BVError.WebSocketErrorReason.connectionFailed
        let errorReasonB = BVError.WebSocketErrorReason.connectionFailed
        let errorReasonC = BVError.WebSocketErrorReason.connectionDisconnected
        
        XCTAssertEqual(errorReasonA, errorReasonA)
        XCTAssertEqual(errorReasonA, errorReasonB)
        XCTAssertNotEqual(errorReasonA, errorReasonC)
        
    }
    
    func testErrorModelDecodingEquatable() {
        
        // Top level
        
        let errorA = BVError.modelDecoding(reason: "Some test error message.")
        let errorB = BVError.modelDecoding(reason: "Some test error message.")
        let errorC = BVError.modelDecoding(reason: "Some different test error message.")

        XCTAssertEqual(errorA, errorA)
        XCTAssertEqual(errorA, errorB)
        XCTAssertNotEqual(errorA, errorC)
        
    }
    
    func testCustomErrorEquatable() {
        
        // Top level
        
        let errorA = BVError.custom(reason: "Reason 1.")
        let errorB = BVError.custom(reason: "Reason 1.")
        let errorC = BVError.custom(reason: "Reason 2.")
        
        XCTAssertEqual(errorA, errorA)
        XCTAssertEqual(errorA, errorB)
        XCTAssertNotEqual(errorA, errorC)
        
    }
    
}
