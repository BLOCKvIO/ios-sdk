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

/// A type that can convert itself into and out of a dictionary representation.
public typealias Dictionaryable = DictionaryCodable & DictionaryDecodable

/// A type that can encode itself from a dictionary representation.
public protocol DictionaryCodable {

    /// Encodes this value into a dictionary.
    func toDictionary() -> [String: Any]
}

/// A type that can decode itself from a dictionary representation.
public protocol DictionaryDecodable {

    /// Creates a new instance by decoding from the given dictionary.
    init(from dictionary: [String: Any]) throws
}

public enum DictionaryDecodingError: Error {
    case failedToDecode
}
