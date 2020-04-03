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

class FaceModelCodable_Tests: XCTestCase {

    // MARK: - Test Methods

    /// Test the decoding where face type is native.
    func testNativeFaceDecoding() {

        do {
            // decode server json into face model
            let model = try TestUtility.jsonDecoder.decode(FaceModel.self,
                                                           from: MockModel.FaceModel.nativeGenericIcon)
            let faceModel = try self.require(model)
            // pack model tests
            XCTAssertEqual(faceModel.id, "48476b21-a4cf-45b6-a2f3-9a9c7b491237")
            XCTAssertEqual(faceModel.templateID, "vatomic.prototyping::Drone2")
            XCTAssertTrue(faceModel.isNative)
            XCTAssertFalse(faceModel.isWeb)
            XCTAssertEqual(faceModel.properties.resources, ["ActivatedImage"])
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    /// Test decoding where face type is Web.
    func testWebFaceDecoding() {

        do {
            // decode server json into face model
            let model = try TestUtility.jsonDecoder.decode(FaceModel.self,
                                                           from: MockModel.FaceModel.webGenericFullscreen)
            let faceModel = try self.require(model)
            // pack model tests
            XCTAssertEqual(faceModel.id, "856a8bc5-ada5-4158-840f-370d27171234c")
            XCTAssertEqual(faceModel.templateID, "vatomic.prototyping::Invitation::v1")
            XCTAssertFalse(faceModel.isNative)
            XCTAssertTrue(faceModel.isWeb)
            XCTAssertEqual(faceModel.properties.resources, ["CardBackground"])
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    func testWebFaceDecodingNullArray() {
        
        do {
            let model = try TestUtility.jsonDecoder.decode(FaceModel.self, from: MockModel.FaceModel.nativeImageV2)
            let faceModel = try self.require(model)
            // pack model tests
            XCTAssertEqual(faceModel.id, "c0231a61-fea4-4110-925c-9998b8812345")
            XCTAssertEqual(faceModel.templateID, "vatomic.prototyping::bridge-tester::unit-test")
            XCTAssertTrue(faceModel.isNative)
            XCTAssertFalse(faceModel.isWeb)
            XCTAssertEqual(faceModel.properties.resources, [])
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }

    /// Test codable (i.e. encode and decode).
    ///
    /// This test checks that encoding the model to data and then decoding back to the original model procduces models
    /// that pass the equality test. This is important for persistance of the models.
    func testCodable() {

        self.decodeEncodeCompare(type: FaceModel.self, from: MockModel.FaceModel.nativeGenericIcon)

    }

}
