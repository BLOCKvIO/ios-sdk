//
//  Dictionaryable.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/02/26.
//

import Foundation

/// A type that can convert itself into and out of a dictionary representation.
public typealias Dictionaryable = DictionaryCodable & DictionaryDecodable

/// A type that can encode itself from a dictionary representation.
public protocol DictionaryCodable {
    
    /// Encodes this value into a dictionary.
    func toDictionary() -> [String : Any]
}

/// A type that can decode itself from a dictionary representation.
public protocol DictionaryDecodable {
    
    /// Creates a new instance by decoding from the given dictionary.
    init(from dictionary: [String : Any]) throws
}

public enum DictionaryDecodingError: Error {
    case failedToDecode
}


