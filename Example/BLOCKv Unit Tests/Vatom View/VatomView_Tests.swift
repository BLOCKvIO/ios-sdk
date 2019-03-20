//
//  VatomView_Tests.swift
//  BLOCKv_Unit_Tests
//
//  Created by Cameron McOnie on 2019/03/13.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import BLOCKv

class VatomView: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// This test asserts that objects set as VatomView's `VatomViewDelegate` received the appropriate delegate messages.
    ///
    /// Issue:
    /// The initialisation pattern of VatomView triggers the VVLC to run immediately not allowing the caller the
    /// opportunity set a delegate.
    func testVatomViewDelegate() {
        
        /// Create packaged vatom
        func createPackagedVatom() throws -> VatomModel {
            // decode json into pack model
            let faceModels = try TestUtility.jsonDecoder.decode([FaceModel].self,
                                                                from: MockModelFaces.testVatom_ImagePolicyTest)
            XCTAssertEqual(faceModels.count, 2)
            
            // decode json into a vatom model
            var vatomModel = try TestUtility.jsonDecoder.decode(VatomModel.self, from: MockModel.VatomModel.basicVatom)
            vatomModel.faceModels = faceModels
            
            return vatomModel
        }
        
        do {
            // create package vatom
            let vatom = try self.require(try? createPackagedVatom())
            
            // custom roster (limit side affects on other tests)
            let customRosterManager = FaceViewRoster()
            customRosterManager.register(ImageFaceView.self)
            customRosterManager.register(ImagePolicyFaceView.self)
            // setup spy delegate
            let vatomViewSpyDelegate = VatomViewSpyDelegate()
            // create expectations
            let didSelectFaceViewExpectation = XCTestExpectation(description: "VatomView calls `didSelectFaceView` after a face view has been selected.")
            let didLoadFaceViewExpectation = XCTestExpectation(description: "VatomView calls `didLoadFaceView` after the face view has completed loading.")
            vatomViewSpyDelegate.didSelectFaceViewAsyncExpectation = didSelectFaceViewExpectation
            vatomViewSpyDelegate.didLoadFaceViewAsyncExpectation = didLoadFaceViewExpectation
            
            // 2. Initialization - Delayed VVLC
            let vatomViewA = VatomView()
            vatomViewA.roster = customRosterManager.roster
            vatomViewA.vatomViewDelegate = vatomViewSpyDelegate
            // trigger vvlc
            vatomViewA.update(usingVatom: vatom)
            
            guard let faceView = vatomViewSpyDelegate.didSelectFaceViewResult else {
                XCTFail("Expected `didSelectFaceView` delegate to be called.")
                return
            }
            XCTAssertTrue(faceView.faceModel.id == "53f4457e-8a1a-4c93-ab92-b4db9f1c1234")
            
            guard let faceView = vatomViewSpyDelegate.didLoadFaceViewResult else {
                XCTFail("Expected `didLoadFaceView` delegate to be called.")
                return
            }
            XCTAssertTrue(faceView.faceModel.id == "53f4457e-8a1a-4c93-ab92-b4db9f1c1234")
            
            /*
             Change to waitForExpectations(:) if the VVLC is run asynchronously.
             */
            
            //            waitForExpectations(timeout: 1) { error in
            //                if let error = error {
            //                    XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            //                }
            //                guard let result = vatomViewSpyDelegate.didSelectFaceViewResult else {
            //                    XCTFail("Expected delegate to be called.")
            //                    return
            //                }
            //                XCTAssertTrue(result)
            //            }
            
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    /// Delegate object to test whether delegate calls are received.
    class VatomViewSpyDelegate: VatomViewDelegate {
        
        var didSelectFaceViewResult: FaceView? = nil
        var didLoadFaceViewResult: FaceView? = nil
        
        // async code needs to fulfill XCTestExpection
        var didSelectFaceViewAsyncExpectation: XCTestExpectation?
        var didLoadFaceViewAsyncExpectation: XCTestExpectation?
        
        /// Delegate method
        func vatomView(_ vatomView: VatomView, didSelectFaceView result: Result<FaceView, VVLCError>) {
            guard let expectation = didSelectFaceViewAsyncExpectation else {
                XCTFail("SpyDelegate was not setup correctly. Missing XCTestExpectatoin reference.")
                return
            }
            // delegate message was received
            switch result {
            case .success(let faceView):
                didSelectFaceViewResult = faceView
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Face View selection failed: \(error.localizedDescription)")
            }
            
        }
        
        // Delegate method
        func vatomView(_ vatomView: VatomView, didLoadFaceView result: Result<FaceView, VVLCError>) {
            guard let expectation = didLoadFaceViewAsyncExpectation else {
                XCTFail("SpyDelegate was not setup correctly. Missing XCTestExpectatoin reference.")
                return
            }
            
            // delegate message was received
            switch result {
            case .success(let faceView):
                didLoadFaceViewResult = faceView
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Face View selection failed: \(error.localizedDescription)")
                return
            }
        }
        
    }
    
    //TODO: Test performance of VVLC

}
