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

/*
 Caveat: `when_modified` is returned as a double.
 */

/// Represents a collection of threads.
public struct ThreadModel: Equatable {

    /// Struct containing a few user properties.
    public struct UserInfo: Codable, Equatable {
        public let name: String
        public let avatarURL: URL?

        enum CodingKeys: String, CodingKey {
            case name = "name"
            case avatarURL = "avatar_uri"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            avatarURL = container.decodeSafely(URL.self, forKey: .avatarURL)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(avatarURL, forKey: .avatarURL)
        }

    }

    /// Unique identifier of the message thread.
    ///
    /// The id is a compound name <user_a>:<user_b>
    public let id: String
    /// HACK - server returns the date as a Double.
    private let _whenModified: Double
    /// Timestamp of when the message thread was modified.
    public let whenModified: Date
    /// Lastest message within this thread.
    public let lastMessage: MessageModel
    /// Info of the interaction user (for the latest message within this thread).
    public let lastMessageUserInfo: UserInfo

    enum CodingKeys: String, CodingKey {
        case id                  = "name"
        case whenModified        = "when_modified"
        case lastMessage         = "last_message"
        case lastMessageUserInfo = "last_message_user_info"
    }

}

/*
 Custom decoding is required due to the `when_modified` property being a double.
 */
extension ThreadModel: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        lastMessage = try container.decode(MessageModel.self, forKey: .lastMessage)
        lastMessageUserInfo = try container.decode(UserInfo.self, forKey: .lastMessageUserInfo)

        // convert the double to date
        _whenModified = try container.decode(Double.self, forKey: .whenModified)
        whenModified = Date(timeIntervalSince1970: _whenModified / 1000)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lastMessage, forKey: .lastMessage)
        try container.encode(lastMessageUserInfo, forKey: .lastMessageUserInfo)
        try container.encode(_whenModified, forKey: .whenModified)
    }

}
