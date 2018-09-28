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

/// Public user response model.
public struct PublicUserModel: Codable, Equatable {

    public let id: String
    public let properties: Properties

    public struct Properties: Codable, Equatable {
        public let firstName: String
        public let lastName: String
        public let avatarURL: URL?

        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName  = "last_name"
            case avatarURL = "avatar_uri"
        }
    }

}
