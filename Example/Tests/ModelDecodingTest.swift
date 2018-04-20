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
import BLOCKv

/// This class is responsible for testing JSON decoding.
class ModelDecodingTest: XCTestCase {
    
    lazy var decoder: JSONDecoder = {
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
    
    // MARK: Login
    
    func testLoginDecoding() {
        
        do {
            let _ = try decoder.decode(BaseModel<AuthModel>.self, from: MockResponse.loginResponse_v1)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
        do {
            let _ = try decoder.decode(BaseModel<AuthModel>.self, from: MockResponse.loginResponse_v2)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: vAtom Resource
    
    func testVatomResourceDecoding() {
        
        do {
            let _ = try decoder.decode([VatomResource].self, from: MockResponse.vatomResourcesJSON_Simple1)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: vAtom
    
    func testVatomDecoding() {
        
        do {
            let vatom = try decoder.decode(Vatom.self, from: MockResponse.vatomJSON_Version1)
            print(vatom)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
        do {
            let _ = try decoder.decode(Vatom.self, from: MockResponse.vatomJSON_Version2)
            
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
        do {
            let _ = try decoder.decode(Vatom.self, from: MockResponse.vatomJSON_Version3)
            
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
        do {
            let _ = try decoder.decode(Vatom.self, from: MockResponse.vatomJSON_ExtendedPrivateSection)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }

        
    }
    
    // MARK: Array of vAtoms
    
    func testVatomArrayDecoding() {
        
        do {
            let blob = MockResponse.vatomArrayJSON_Version1
            let model = try decoder.decode([Safe<Vatom>].self, from: blob)
            print("\n Decoded \(model.count) of \(blob.count)")
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
        do {
            let blob = MockResponse.vatomArrayJSON_Version2
            let model = try decoder.decode([Safe<Vatom>].self, from: blob)
            print("\n Decoded \(model.count) of \(blob.count)")
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: Face
    
    func testFaceDecoding() {
        
        do {
            let _ = try decoder.decode(Face.self, from: MockResponse.vatomFaceJSON)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: - Action
    
    func testActionDecoding() {
        
        do {
            let _ = try decoder.decode(Action.self, from: MockResponse.vatomActionJSON)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: Group
    
    func testGroupModelDecoding() {
        
        do {
            let _ = try decoder.decode(GroupModel.self, from: MockResponse.groupModelJSON_Version1)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: Inventory
    
    /// Tests inventory decoding. Matches server response.
    func testInventoryDecoding() {
        
        do {
            let _ = try decoder.decode(BaseModel<GroupModel>.self, from: MockResponse.inventoryServerResponseJSON_Version1)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            do {
                let _ = try decoder.decode(Vatom.self, from: MockResponse.vatomJSON_Version1)
            } catch {
                XCTFail("Decoding failed: \(error.localizedDescription)")
            }
        }
    }
    
}
