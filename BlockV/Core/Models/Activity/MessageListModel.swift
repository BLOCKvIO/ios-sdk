//
//  BLOCKv AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BLOCKv SDK License (the "License"); you may not use this file or
//  the BLOCKv SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BLOCKv SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import Foundation

/// Represents a list of messages within a thread.
public struct MessageListModel: Equatable {

    /*
     The InnerModel abstracts the wierd nesting that the server returns.
     This may be achieved using a CodingKey instead.
     */

    // Inner model
    struct InnerModel: Codable {
        let message: MessageModel
//        let whenModified: Date

        enum CodingKeys: String, CodingKey {
            case message
//            case whenModified = "when_modified"
        }

        init(message: MessageModel) {
            self.message = message
        }

        // MARK: - Codable

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.message = try container.decode(MessageModel.self, forKey: .message)
            // convert the double to date
//            let _whenModified = try container.decode(Double.self, forKey: .whenModified)
//            whenModified = Date(timeIntervalSince1970: _whenModified / 1000)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(message, forKey: .message)
        }

    }

    /// Filters out all threads more recent than the cursor (useful for paging).
    public var cursor: String
    /// Array of messages for the specifed thread.
    public var messages: [MessageModel]

    enum CodingKeys: String, CodingKey {
        case cursor
        case messages
    }

}

extension MessageListModel: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cursor = try container.decode(String.self, forKey: .cursor)
        let inner = container.decodeSafelyArray(of: InnerModel.self, forKey: .messages)
        self.messages = inner.map { $0.message }
        print(self.messages)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cursor, forKey: .cursor)
        let innerWrapper = messages.map { InnerModel(message: $0) }
        try container.encode(innerWrapper, forKey: .messages)
    }

}
