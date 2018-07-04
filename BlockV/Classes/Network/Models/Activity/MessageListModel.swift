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

    /*
     The InnerModel abstracts the wierd nesting that the server returns.
     This may be achieved using a CodingKey instead.
     */

    // Inner model
    struct InnerModel: Decodable {
        let message: MessageModel
//        let whenModified: Date

        enum CodingKeys: String, CodingKey {
            case message
            case whenModified = "when_modified"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.message = try container.decode(MessageModel.self, forKey: .message)
            // convert the double to date
//            let _whenModified = try container.decode(Double.self, forKey: .whenModified)
//            whenModified = Date(timeIntervalSince1970: _whenModified / 1000)
        }

    }

    /// Filters out all threads more recent than the cursor (useful for paging).
    public let cursor: String
    /// Array of messages for the specifed thread.
    public let messages: [MessageModel]

    enum CodingKeys: String, CodingKey {
        case cursor
        case messages
    }

}

extension MessageListModel: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cursor = try container.decode(String.self, forKey: .cursor)
        //print(self.cursor)
        let inner = container.decodeSafelyArray(of: InnerModel.self, forKey: .messages)
        //print(inner)
        self.messages = inner.map { $0.message }
        print(self.messages)
    }

}
