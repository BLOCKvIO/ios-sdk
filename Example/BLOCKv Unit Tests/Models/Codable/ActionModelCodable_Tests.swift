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

/*
 Codable JSON Gotcha:
 Codable may produce an escaped JSON string – this is valid JSON, but makes string comparison difficult.
 */

class ActionModelCodable_Tests: XCTestCase {
    
    func testActionDecoding() {
        
        do {
            let _ = try TestUtility.jsonDecoder.decode(ActionModel.self, from: MockModel2.vatomActionJSON)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }
        
    }
    
    func testActionModelCodable() {
        
        do {
            // convert: json data (server format) -> model
            let model = try TestUtility.jsonDecoder.decode(ActionModel.self, from: MockModel2.vatomActionJSON)
            let modelFromJSONData = try self.require(model)
            // convert: model -> json data
            let data = try TestUtility.jsonEncoder.encode(modelFromJSONData)
            // convert: json data (encoded format) -> model
            let modelFromEncodedData = try TestUtility.jsonDecoder.decode(ActionModel.self, from: data)
            
            // ensure that server and encoded formats are the same
            XCTAssertEqual(modelFromJSONData, modelFromEncodedData)
            
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
}
