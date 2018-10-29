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

class KeyPath_Tests: XCTestCase {
    
    func testHeadAndTailEmpty() {
        let keyPath = KeyPath("")
        do {
            let headAndTail = try self.require(keyPath.headAndTail())
            XCTAssertEqual(headAndTail.head, "")
            XCTAssertEqual(headAndTail.tail, KeyPath())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testHeadAndTailSingle() {
        let keyPath = KeyPath("a")
        do {
            let headAndTail = try self.require(keyPath.headAndTail())
            XCTAssertEqual(headAndTail.head, "a")
            XCTAssertEqual(headAndTail.tail, KeyPath())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testHeadAndTailDouble() {
        let keyPath = KeyPath("a.b")
        do {
            let headAndTail = try self.require(keyPath.headAndTail())
            XCTAssertEqual(headAndTail.head, "a")
            XCTAssertEqual(headAndTail.tail, KeyPath("b"))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testHeadAndTailTripple() {
        let keyPath = KeyPath("a.b.c")
        do {
            let headAndTail = try self.require(keyPath.headAndTail())
            XCTAssertEqual(headAndTail.head, "a")
            XCTAssertEqual(headAndTail.tail, KeyPath("b.c"))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
   
    
}


class GenericJSONKeyPath_Tests: XCTestCase {
    
    private let someJSON: JSON = [
        "a": "x",
        "b": "y",
        "c": [
            "foo": "bar",
            "tar": [1, 2, 3]
        ]
    ]
    
    func testDictionaryKeyPathLookup() {
        let a = someJSON[keyPath: "a"]
        let b = someJSON[keyPath: "b"]
        let c = someJSON[keyPath: "c.foo"]
        let d = someJSON[keyPath: "c.tar"]
        
        do {
            let a = try self.require(a?.stringValue)
            XCTAssertEqual(a, "x")
            let b = try self.require(b?.stringValue)
            XCTAssertEqual(b, "y")
            let c = try self.require(c?.stringValue)
            XCTAssertEqual(c, "bar")
            let tar = try self.require(d?.arrayValue)
            XCTAssertEqual(tar, [1, 2, 3])
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
}

