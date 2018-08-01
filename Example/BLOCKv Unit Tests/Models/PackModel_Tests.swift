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

class PackModel_Tests: XCTestCase {
    
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    /// Must be available to every test method.
    var packModel: PackModel!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        do {
            // decode json into pack model
            let packModel = try decoder.decode(BaseModel<PackModel>.self, from: MockModel.PackModel.Example1).payload
            self.packModel = try self.require(packModel)
            // pack model tests
            XCTAssertEqual(self.packModel.vatoms.count, 3)
            XCTAssertEqual(self.packModel.faces.count, 14)
            XCTAssertEqual(self.packModel.actions.count, 15)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /// Test the decoding of json to a native PackModel.
    ///
    ///
    func testPackModelDecoding() {
        
        // pack model tests
        XCTAssertEqual(self.packModel.vatoms.count, 3)
        XCTAssertEqual(self.packModel.faces.count, 14)
        XCTAssertEqual(self.packModel.actions.count, 15)
        
    }
    
    /// Test the filter for finding a vAtom.
    func testFilterForVatom() {
        
        let singlePack = self.packModel.filter(whereVatomId: "4389ec35-9fc4-4f31-1232-8cb6bcaa8b19")
        // single pack
        XCTAssertEqual(singlePack.vatoms.count, 1)
        XCTAssertEqual(singlePack.faces.count, 2)
        XCTAssertEqual(singlePack.actions.count, 1)
        
        do {
            // test `findVatom`
            let v = packModel.findVatom(whereId: "4389ec35-9fc4-4f31-1232-8cb6bcaa8b19")
            let vatom = try self.require(v)
            // ensure id of returned vatom matches the specified vatom id
            XCTAssertEqual(vatom.id, "4389ec35-9fc4-4f31-1232-8cb6bcaa8b19")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    /// Test the filter for faces associated with a vAtom.
    func testFilterForFaces() {
        
        // test `fitlerFaces`
        let faces = packModel.filterFaces(whereVatomId: "009b12ac-bd27-4bb4-a123-73faa2f0e270")
        
        // ensure correct totoal number of faces
        XCTAssertEqual(faces.count, 6)
        // ensure each face has the correct template id
        XCTAssertEqual((faces.filter {$0.templateID == "vatomic.prototyping::ProgressRedeem::v1"} ).count, 6)
        
    }
    
    /// Test the fileter for actions associated with a vAtom.
    func testFilterForActions() {
        
        // test `filterActions`
        let actions = packModel.filterActions(whereVatomId: "009b12ac-bd27-4bb4-a123-73faa2f0e270")

        // ensure correct total number of actions
        XCTAssertEqual(actions.count, 8)
        // ensure each actions has the correct template id
        XCTAssertEqual((actions.filter {$0.templateID == "vatomic.prototyping::ProgressRedeem::v1"} ).count, 8)
        
    }
    
}
