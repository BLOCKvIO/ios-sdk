//
//  GenericJsonMerge_Tests.swift
//  BLOCKv_Unit_Tests
//
//  Created by Cameron McOnie on 2018/10/17.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
@testable import BLOCKv

class GenericJsonMerge_Tests: XCTestCase {
    
    //    func testDifferingTypes() {
    //        let A = JSON("a")
    //        let B = JSON(1)
    //
    //        do {
    //            _ = try A.merged(with: B)
    //        } catch let error as SwiftyJSONError {
    //            XCTAssertEqual(error.errorCode, SwiftyJSONError.wrongType.rawValue)
    //            XCTAssertEqual(type(of: error).errorDomain, SwiftyJSONError.errorDomain)
    //            XCTAssertEqual(error.errorUserInfo as! [String: String], [NSLocalizedDescriptionKey: "Couldn't merge, because the JSONs differ in type on top level."])
    //        } catch _ {}
    //    }
    
    func testPrimitiveStringType() {
        let A = try! JSON("a")
        let B = try! JSON("b")
        XCTAssertEqual(try! A.merged(with: B), B)
    }
    
    func testPrimativeNumberType() {
        let A = try! JSON(123)
        let B = try! JSON(456)
        XCTAssertEqual(try! A.merged(with: B), B)
    }
    
    func testMergeEqual() {
        let json = try! JSON(["a": "A"])
        XCTAssertEqual(try! json.merged(with: json), json)
    }
    
    func testMergeUnequalValues() {
        let A = try! JSON(["a": "A"])
        let B = try! JSON(["a": "B"])
        XCTAssertEqual(try! A.merged(with: B), B)
    }
    
    func testMergeUnequalKeysAndValues() {
        let A = try! JSON(["a": "A"])
        let B = try! JSON(["b": "B"])
        XCTAssertEqual(try! A.merged(with: B), try! JSON(["a": "A", "b": "B"]))
    }
    
    func testMergeFilledAndEmpty() {
        let A = try! JSON(["a": "A"])
        let B = try! JSON([:])
        XCTAssertEqual(try! A.merged(with: B), A)
    }
    
    func testMergeEmptyAndFilled() {
        let A = try! JSON([:])
        let B = try! JSON(["a": "A"])
        XCTAssertEqual(try! A.merged(with: B), B)
    }
    
    func testMergeArray() {
        let A = try! JSON(["a"])
        let B = try! JSON(["b"])
        XCTAssertEqual(try! A.merged(with: B), B)
    }
    
    func testMergeNestedJSONs() {
        let A = try! JSON([
            "nested": [
                "a": "A"
            ]
            ])
        
        let B = try! JSON([
            "nested": [
                "a": "B"
            ]
            ])
        
        XCTAssertEqual(try! A.merged(with: B), B)
    }
    
    func testMergeNull() {
        
        let A = JSON.null
        let B = JSON.object(["a": "A"])
        XCTAssertEqual(try! A.merged(with: B), B)
        
        let C = JSON.object(["a": "A"])
        let D = JSON.null
        XCTAssertEqual(try! C.merged(with: D), D)

    }

}
