//
//  EmbeddedProcedure_Tests.swift
//  BLOCKv_Unit_Tests
//
//  Created by Cameron McOnie on 2018/08/16.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BLOCKv

class EmbeddedProcedure_Tests: XCTestCase {
    
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
            // decode json into pack model
            let faceModels = try decoder.decode([FaceModel].self, from: MockModelFaces.genericIconAnd3D)
            XCTAssertEqual(faceModels.count, 2)
            
            let possibleBestFaceForIcon = EmbeddedProcedure.icon.selectBestFace(from: faceModels)
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
            
            let possibleBestFaceForCard = EmbeddedProcedure.card.selectBestFace(from: faceModels)
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
