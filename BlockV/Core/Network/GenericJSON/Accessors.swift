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

import Foundation

// MARK: - Accessors

public extension JSON {

    /// Return the string value if this is a `.string`, otherwise `nil`
    public private(set) var stringValue: String? {
        get {
            if case .string(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self = JSON(stringLiteral: newValue)
            } else {
                self = JSON.null
            }
        }
    }

    /// Return the float value if this is a `.number`, otherwise `nil`
    public private(set) var floatValue: Float? {
        get {
            if case .number(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self = JSON(floatLiteral: newValue)
            } else {
                self = JSON.null
            }
        }
    }

    /// Return the bool value if this is a `.bool`, otherwise `nil`
    public private(set)  var boolValue: Bool? {
        get {
            if case .bool(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self = JSON(booleanLiteral: newValue)
            } else {
                self = JSON.null
            }
        }
    }

    /// Return the object value if this is an `.object`, otherwise `nil`
    public private(set) var objectValue: [String: JSON]? {
        get {
            if case .object(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self = JSON.object(newValue)
            } else {
                self = JSON.null
            }
        }
    }

    /// Return the array value if this is an `.array`, otherwise `nil`
    public private(set) var arrayValue: [JSON]? {
        get {
            if case .array(let value) = self {
                return value
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self =  JSON.array(newValue)
            } else {
                self = JSON.null
            }
        }

    }

    /// Return `true` iff this is `.null`
    public var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }

    /// If this is an `.array`, return item at index
    ///
    /// If this is not an `.array` or the index is out of bounds, returns `nil`.
    public private(set) subscript(index: Int) -> JSON? {
        get {
            if case .array(let arr) = self, arr.indices.contains(index) {
                return arr[index]
            }
            return nil
        }
        set {
            if case .array(var arr) = self, arr.indices.contains(index) {
                if let newValue = newValue {
                    arr[index] = newValue // update value at index
                    self = JSON.array(arr)
                } else {
                    self = JSON.null
                }
            }
        }
    }

    /// If this is an `.object`, return item at key
    public private(set) subscript(key: String) -> JSON? {
        get {
            if case .object(let dict) = self {
                return dict[key]
            }
            return nil
        }
        set {
            if case .object(var obj) = self {
                obj[key] = newValue
                self = JSON.object(obj)
            }
        }
    }

    /// Dynamic member lookup sugar for string subscripts
    ///
    /// This lets you write `json.foo` instead of `json["foo"]`.
    public subscript(dynamicMember member: String) -> JSON? {
        return self[member]
    }

}

// MARK: - JSON Partial Update

extension JSON {

    /// Merges a JSON type into this JSON.
    ///
    /// Primative values which are not present in this JSON are NOT added.
    /// Primative values which are present are overwritten.
    /// Array values are appended.
    /// Nested JSON is handled in the same way.
    private mutating func merge(with other: JSON) {
        self.merge(with: other, typecheck: true)
    }

    /// Merges a JSON type into this JSON and returns a copy.
    ///
    internal func updated(applying other: JSON) -> JSON {
        var copy = self
        copy.merge(with: other, typecheck: true)
        return copy
    }

    /// Worker function which performs a mutating merge.
    ///
    /// The keys of other are used to merge into self.
    /// Both self and other must have the same top level json structure.
    /// Type checking is not enforced. If types do not match, the right replaces the left.
    private mutating func merge(with other: JSON, typecheck: Bool) {

        switch self {
        case .object:
            if let otherObject = other.objectValue {
                for (key, _) in otherObject {
                    if self[key] != nil {
                        try self[key]!.merge(with: otherObject[key]!, typecheck: false)
                    } else {
                        self[key] = otherObject[key] // add it
                    }
                }
            } else {
                self = other
            }
        default:
            // primatives, nulls, and arrays are replaced
            self = other
        }

    }

}
