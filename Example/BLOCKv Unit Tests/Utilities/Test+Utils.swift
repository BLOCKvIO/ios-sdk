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

extension XCTestCase {

    // We conform to LocalizedError in order to be able to output
    // a nice error message.
    private struct RequireError<T>: LocalizedError {
        let file: StaticString
        let line: UInt
        // It's important to implement this property, otherwise we won't
        // get a nice error message in the logs if our tests starts to fail.
        var errorDescription: String? {
            return "Required value of type \(T.self) was nil at line \(line) in file \(file)."
        }
    }
    // Using file and line lets us automatically capture where
    // the expression took place in our source code.
    public func require<T>(_ expression: @autoclosure () -> T?, file: StaticString = #file, line: UInt = #line) throws -> T {
        guard let value = expression() else {
            throw RequireError<T>(file: file, line: line)
        }
        return value
    }

}

extension XCTestCase {

    /// Tests decoding data to a concrete type, and then encoding the concrete type to data.
    /// Finally, the original data and the encoded data are compared.
    func decodeEncodeCompare<T: Codable & Equatable>(type: T.Type, from data: Data) {

        do {
            // decode server data (api json) into concrete type
            let model = try TestUtility.jsonDecoder.decode(type.self, from: data)
            let modelFromJSONData = try self.require(model)
            // encode to data
            let encodedData = try TestUtility.jsonEncoder.encode(modelFromJSONData)
            // decode encoded data (codable machineary) into a concrete type
            let modelFromEncodedData = try TestUtility.jsonDecoder.decode(type, from: encodedData)

            XCTAssertEqual(modelFromJSONData, modelFromEncodedData)

        } catch {
            XCTFail(error.localizedDescription)
        }

    }

}

// MARK: - BLOCKv Helpers

class TestUtility {

    //TODO: Replace with blockv decoder
    static var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    //TODO: Replace with blockv encoder
    static var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

}

/// Represents the top-level JSON structure for success on BLOCKv platform responses.
///
/// This is an extension of BLOCKv's BaseModel. It adds full Codable conformance. Once `BaseModel` supports
/// Codable this type may be removed.
public struct BaseModelTest<T>: Codable, Equatable where T: Codable & Equatable {
    let payload: T
}
