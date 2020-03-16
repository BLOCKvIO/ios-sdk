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

class VatomModelCodable_Tests: XCTestCase {

    // MARK: vAtom Resource

    func testVatomResourceDecoding() {

        do {
            _ = try TestUtility.jsonDecoder.decode([VatomResourceModel].self, from: MockModel2.vatomResourcesJSON_Simple1)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }

    }

    // MARK: vAtom

    func testVatomDecoding() {

        do {
            let vatom = try TestUtility.jsonDecoder.decode(VatomModel.self, from: MockModel2.vatomJSON_Version1)
            print(vatom)
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }

    }

    // MARK: Array of vAtoms

    func testVatomArrayDecoding() {

        do {
            let blob = MockModel2.vatomArrayJSON_Version1
            let model = try TestUtility.jsonDecoder.decode([Safe<VatomModel>].self, from: blob)
            print("\n Decoded \(model.count) of \(blob.count)")
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }

        do {
            let blob = MockModel2.vatomArrayJSON_Version2
            let model = try TestUtility.jsonDecoder.decode([Safe<VatomModel>].self, from: blob)
            print("\n Decoded \(model.count) of \(blob.count)")
        } catch {
            XCTFail("Decoding failed: \(error.localizedDescription)")
        }

    }

}
