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


extension Sequence {
    /// Similar to
    /// ```
    /// func forEach(@noescape body: (Self.Generator.Element) -> ())
    /// ```
    /// but calls the completion block once all blocks have called their completion block. If some of the calls to the block do not call their completion blocks that will result in data leaking.
    
    func asyncForEach(completion: @escaping () -> (), block: (Iterator.Element, @escaping () -> ()) -> ()) {
        let group = DispatchGroup()
        let innerCompletion = { group.leave() }
        for x in self {
            group.enter()
            block(x, innerCompletion)
        }
        group.notify(queue: DispatchQueue.main, execute: completion)
    }
    
    func all(_ condition: (Iterator.Element) -> Bool) -> Bool {
        for x in self where !condition(x) {
            return false
        }
        return true
    }
    
    func some(_ condition: (Iterator.Element) -> Bool) -> Bool {
        for x in self where condition(x) {
            return true
        }
        return false
    }
}


extension Sequence where Iterator.Element: AnyObject {
    public func containsObjectIdentical(to object: AnyObject) -> Bool {
        return contains { $0 === object }
    }
}


extension Array {
    var decomposed: (Iterator.Element, [Iterator.Element])? {
        guard let x = first else { return nil }
        return (x, Array(self[1..<count]))
    }
    
    func sliced(size: Int) -> [[Iterator.Element]] {
        var result: [[Iterator.Element]] = []
        for idx in stride(from: startIndex, to: endIndex, by: size) {
            let end = Swift.min(idx + size, endIndex)
            result.append(Array(self[idx..<end]))
        }
        return result
    }
}


extension URL {
    static var temporary: URL {
        return URL(fileURLWithPath:NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
    }
    
    static var documents: URL {
        return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
}


//extension String {
//    public func removingCharacters(in set: CharacterSet) -> String {
//        var chars = characters //FIXME: Swift version issue
//        for idx in chars.indices.reversed() {
//            if set.contains(String(chars[idx]).unicodeScalars.first!) {
//                chars.remove(at: idx)
//            }
//        }
//        return String(chars)
//    }
//}
