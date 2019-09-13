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
import GenericJSON

/// Simple struct that models a key path.
struct KeyPath {
    private(set) var segments: [String]

    typealias Separator = (String) -> [String]
    // default separator uses standard period separation
    private(set) var separator: Separator = { $0.components(separatedBy: ".") }

    var isEmpty: Bool { return segments.isEmpty }
    var path: String {
        return segments.joined(separator: ".")
    }

    /// Strips off the first segment and returns a pair consisting of the first segment and the remaining key path.
    /// Returns `nil` if the key path has no segments.
    func headAndTail() -> (head: String, tail: KeyPath)? {
        guard !isEmpty else { return nil }
        var tail = segments
        let head = tail.removeFirst()
        return (head, KeyPath(tail))
    }

}

extension KeyPath: Equatable {
    static func == (lhs: KeyPath, rhs: KeyPath) -> Bool {
        return lhs.segments == rhs.segments
    }
}

/// Initializes a KeyPath with a string of the form "this.is.a.keypath"
extension KeyPath {
    init(_ string: String, separator: Separator? = nil) {
        if let sep = separator { self.separator = sep }
        segments = self.separator(string)
    }

    init(_ segments: [String], separator: Separator? = nil) {
        if let sep = separator { self.separator = sep }
        self.segments = segments
    }
}

/// Initializ a KeyPath using a string literal.
extension KeyPath: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(value)
    }
    init(unicodeScalarLiteral value: String) {
        self.init(value)
    }
    init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
}

// MARK: - Dictionary Keypath

extension Dictionary where Key == String {
    subscript(keyPath keyPath: KeyPath) -> Any? {
        get {
            switch keyPath.headAndTail() {
            case nil:
                // key path is empty.
                return nil
            case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
                // Reached the end of the key path.
                let key = Key(stringLiteral: head)
                return self[key]
            case let (head, remainingKeyPath)?:
                // Key path has a tail we need to traverse.
                let key = Key(stringLiteral: head)
                switch self[key] {
                case let nestedDict as [Key: Any]:
                    // Next nest level is a dictionary.
                    // Start over with remaining key path.
                    return nestedDict[keyPath: remainingKeyPath]
                default:
                    // Next nest level isn't a dictionary.
                    // Invalid key path, abort.
                    return nil
                }
            }
        }
        set {
            switch keyPath.headAndTail() {
            case nil:
                // key path is empty.
                return
            case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
                // Reached the end of the key path.
                let key = Key(stringLiteral: head)
                self[key] = newValue as? Value
            case let (head, remainingKeyPath)?:
                let key = Key(stringLiteral: head)
                let value = self[key]
                switch value {
                case var nestedDict as [Key: Any]:
                    // Key path has a tail we need to traverse
                    nestedDict[keyPath: remainingKeyPath] = newValue
                    self[key] = nestedDict as? Value
                default:
                    // Invalid keyPath
                    return
                }
            }
        }
    }
}

// MARK: - Vatom KeyPath Lookup

extension VatomModel {

    /// Returns the value for the given keypath (or `nil` if the keypath cannot be parsed).
    public func valueForKeyPath(_ keypath: String) -> JSON? {

        /*
         A custom separator  is needed due to Varius's regrettable property names which contain escaped quotes
         around period-separated names. For example:
         "private.state.\"a.b:v.io:countdown-timer-v1\".value"
         */

        // create separator
        let regularExpression = try! NSRegularExpression(pattern: "\\.(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)")
        let separator: (String) -> [String] = { $0.split(usingRegex: regularExpression) }

        // create keypath and split into head and tail
        guard let component = KeyPath(keypath, separator: separator).headAndTail() else { return nil }

        var vatomValue: JSON?
        // extract vatom value
        if component.head == "private" {
            vatomValue = self.private?[keyPath: component.tail.path]
        } else if component.head == "vAtom::vAtomType" {

            if component.tail.path == "cloning_score" {
                vatomValue = try? JSON(self.props.cloningScore)
            } else if component.tail.path == "num_direct_clones" {
                vatomValue = try? JSON(self.props.numberDirectClones)
            } else if component.tail.path == "parent_id" {
                vatomValue = try? JSON(self.props.parentID)
            } else if component.tail.path == "dropped" {
                vatomValue = try? JSON(self.props.isDropped)
            } else if component.tail.path == "transferable" {
                vatomValue = try? JSON(self.props.isTransferable)
            } else if component.tail.path == "acquirable" {
                vatomValue = try? JSON(self.props.isAcquirable)
            } else if component.tail.path == "redeemable" {
                vatomValue = try? JSON(self.props.isRedeemable)
            }

        }

        return vatomValue

    }

}
