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

/// A JSON value representation. This is a bit more useful than the naïve `[String:Any]` type
/// for JSON values, since it makes sure only valid JSON values are present & supports `Equatable`
/// and `Codable`, so that you can compare values for equality and code and decode them into data
/// or strings.
public enum JSON {
    case string(String)
    case number(Float)
    case object([String:JSON])
    case array([JSON])
    case bool(Bool)
    case null
}

// swiftlint:disable identifier_name
extension JSON: Equatable {

    public static func == (lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs, rhs) {
        case (.string(let s1), .string(let s2)):
            return s1 == s2
        case (.number(let n1), .number(let n2)):
            return n1 == n2
        case (.object(let o1), .object(let o2)):
            return o1 == o2
        case (.array(let a1), .array(let a2)):
            return a1 == a2
        case (.bool(let b1), .bool(let b2)):
            return b1 == b2
        case (.null, .null):
            return true
        default:
            return false
        }
    }
}
// swiftlint:enable identifier_name

extension JSON: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .string(let str):
            return str.debugDescription
        case .number(let num):
            return num.debugDescription
        case .bool(let bool):
            return bool.description
        case .null:
            return "null"
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            return try! String(data: encoder.encode(self), encoding: .utf8)!
        }
    }
}
