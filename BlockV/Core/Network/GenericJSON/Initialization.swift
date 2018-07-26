//  MIT License
//
//  Copyright (c) 2017 Tomáš Znamenáček (http://zoul.cz/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

extension JSON {

    /// Create a JSON value from anything. Argument has to be a valid JSON structure:
    /// A `Float`, `Int`, `String`, `Bool`, an `Array` of those types or a `Dictionary`
    /// of those types.
    public init(_ value: Any) throws {
        switch value {
        case let num as Float:
            self = .number(num)
        case let num as Int:
            self = .number(Float(num))
        case let str as String:
            self = .string(str)
        case let bool as Bool:
            self = .bool(bool)
        case let array as [Any]:
            self = .array(try array.map(JSON.init))
        case let dict as [String: Any]:
            self = .object(try dict.mapValues(JSON.init))
        default:
            throw BVJSONError.decodingError
        }
    }
}

extension JSON {

    /// Create a JSON value from a `Codable`. This will give you access to the “raw”
    /// encoded JSON value the `Codable` is serialized into. And hopefully, you could
    /// encode the resulting JSON value and decode the original `Codable` back.
    public init<T: Codable>(codable: T) throws {
        let encoded = try JSONEncoder().encode(codable)
        self = try JSONDecoder().decode(JSON.self, from: encoded)
    }
}

extension JSON: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSON: ExpressibleByNilLiteral {

    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSON: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: JSON...) {
        self = .array(elements)
    }
}

extension JSON: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, JSON)...) {
        var object: [String: JSON] = [:]
        for (k, v) in elements { // swiftlint:disable:this identifier_name
            object[k] = v
        }
        self = .object(object)
    }
}

extension JSON: ExpressibleByFloatLiteral {

    public init(floatLiteral value: Float) {
        self = .number(value)
    }
}

extension JSON: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) {
        self = .number(Float(value))
    }
}

extension JSON: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = .string(value)
    }
}
