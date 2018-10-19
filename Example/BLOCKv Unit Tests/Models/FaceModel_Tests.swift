//
//  FaceModel_Tests.swift
//  BLOCKv_Unit_Tests
//
//  Created by Cameron McOnie on 2018/08/02.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BLOCKv

class FaceModel_Tests: XCTestCase {
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Test Methods
    
    /// Test the decoding where face type is native.
    func testNativeFaceDecoding() {
        
        do {
            // decode server json into face model
            let model = try TestUtility.jsonDecoder.decode(FaceModel.self, from: MockModel.FaceModel.nativeGenericIcon)
            let faceModel = try self.require(model)
            // pack model tests
            XCTAssertEqual(faceModel.id, "48476b21-a4cf-45b6-a2f3-9a9c7b491237")
            XCTAssertEqual(faceModel.templateID, "vatomic.prototyping::Drone2")
            XCTAssertTrue(faceModel.isNative)
            XCTAssertFalse(faceModel.isWeb)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    /// Test decoding where face type is Web.
    func testWebFaceDecoding() {
        
        do {
            // decode server json into face model
            let model = try TestUtility.jsonDecoder.decode(FaceModel.self, from: MockModel.FaceModel.webGenericFullscreen)
            let faceModel = try self.require(model)
            // pack model tests
            XCTAssertEqual(faceModel.id, "856a8bc5-ada5-4158-840f-370d27171234c")
            XCTAssertEqual(faceModel.templateID, "vatomic.prototyping::Invitation::v1")
            XCTAssertFalse(faceModel.isNative)
            XCTAssertTrue(faceModel.isWeb)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    /// Test codable (i.e. encode and decode).
    ///
    /// This test checks that encoding the model to data and then decoding back to the original model procduces models
    /// that pass the equality test. This is important for persistance of the models.
    func testCodable() {
        
        do {
            // decode server json into face model
            let model = try TestUtility.jsonDecoder.decode(FaceModel.self, from: MockModel.FaceModel.nativeGenericIcon)
            let modelFromJSONData = try self.require(model)
            // encode to data
            let data = try TestUtility.jsonEncoder.encode(modelFromJSONData)
            // decode into face model
            let modelFromEncodedData = try TestUtility.jsonDecoder.decode(FaceModel.self, from: data)
            
            print(modelFromJSONData)
            print(modelFromEncodedData)
            
            XCTAssertEqual(modelFromJSONData, modelFromEncodedData)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
