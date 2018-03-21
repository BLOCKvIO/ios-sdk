//
//  BaseModel.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/02/21.
//

import Foundation

/// Represents the top-level JSON structure for success (200...299) BlockV Platform responses.
public struct BaseModel<T: Decodable> : Decodable {
    let payload: T
}

/// Represents a meta data object.
///
/// This structure forms part of a subset of responses.
public struct MetaModel: Codable {
    let dataType: String
    public let whenCreated: Date
    public let whenModified: Date
    
    enum CodingKeys: String, CodingKey {
        case dataType = "data_type"
        case whenCreated = "when_created"
        case whenModified = "when_modified"
    }
    
}

// Every value type should be equatable.
extension MetaModel: Equatable {}

public func ==(lhs: MetaModel, rhs: MetaModel) -> Bool {
    return lhs.dataType == rhs.dataType &&
    lhs.whenCreated == rhs.whenCreated &&
    lhs.whenModified == rhs.whenModified
}
