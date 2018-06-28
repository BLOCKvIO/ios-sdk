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

/// Represents a list of messages within a thread.
public struct MessageListModel: Equatable {
    
    ///
    public let cursor: String
    /// Array of messages for the specifed thread.
    public let messages: [MessageModel]
    
    enum CodingKeys: String, CodingKey {
        case cursor
        case messages
    }
    
}

extension MessageListModel: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cursor = try container.decode(String.self, forKey: .cursor)
        self.messages = container.decodeSafelyArray(of: MessageModel.self, forKey: .messages)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cursor, forKey: .cursor)
        try container.encode(messages, forKey: .messages)
    }
    
}
