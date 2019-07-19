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

/// Eth address response model.
public struct AddressAccountModel: Codable, Equatable {
    
    public let id: String
    public let userId: String
    public let address: String
    public let type: String
    public let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case address
        case type
        case createdAt = "created_at"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        address = try container.decode(String.self, forKey: .address)
        type = try container.decode(String.self, forKey: .type)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(address, forKey: .address)
        try container.encode(type, forKey: .type)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
}

