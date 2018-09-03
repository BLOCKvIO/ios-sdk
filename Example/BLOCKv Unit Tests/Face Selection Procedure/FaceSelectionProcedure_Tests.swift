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

class FaceSelectionProcedure_Tests: XCTestCase {
    
    //TODO: Replace with official blockv decoder
    lazy private var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Tests
    
    ///TODO: This does not yet test whether the native face is installed.
    func testEmbeddedIconSelectionProcedure() {
        
        do {
            
            // decode json into face models
            let faceModels = try decoder.decode([FaceModel].self, from: MockModelFaces.genericIconAnd3D)
            XCTAssertEqual(faceModels.count, 2)
            
            // decode json into a vatom model
            var vatomModel = try decoder.decode(VatomModel.self, from: MockModel.VatomModel.basicVatom)
            vatomModel.faceModels = faceModels
            
            let possibleBestFaceForIcon = EmbeddedProcedure.icon.procedure(vatomModel,
                                                                           ["native://image", "native://generic-3d"])
            
            let bestFaceForIcon = try self.require(possibleBestFaceForIcon)
            XCTAssertEqual(bestFaceForIcon.id, "bbbb")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    func testEmbeddedCardSelectionProcedure() {
        
        do {
            // decode json into pack model
            let faceModels = try decoder.decode([FaceModel].self, from: MockModelFaces.genericIconAnd3D)
            XCTAssertEqual(faceModels.count, 2)
            
            // decode json into a vatom model
            var vatomModel = try decoder.decode(VatomModel.self, from: MockModel.VatomModel.basicVatom)
            vatomModel.faceModels = faceModels
            
            let possibleBestFaceForCard = EmbeddedProcedure.card.procedure(vatomModel,
                                                                           ["native://image", "native://generic-3d"])
            let bestFaceForCard = try self.require(possibleBestFaceForCard)
            XCTAssertEqual(bestFaceForCard.id, "aaaa")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
