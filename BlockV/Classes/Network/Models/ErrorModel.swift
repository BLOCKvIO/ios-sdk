//
//  ErrorModel.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/02/27.
//

import Foundation

/// Error model returned by the Blockv server.
struct ErrorModel {
    let code: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case code = "error"
        case message
    }
    
}

extension ErrorModel: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(Int.self, forKey: .code) ?? -1
        message = try container.decode(String.self, forKey: .message)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
    }
    
}

// MARK: - Equatable

// Every value type should be equatable.
extension ErrorModel: Equatable {}

func ==(lhs: ErrorModel, rhs: ErrorModel) -> Bool {
    return lhs.code == rhs.code &&
    lhs.message == rhs.message
}
