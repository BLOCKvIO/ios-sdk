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
import GenericJSON

//swiftlint:disable identifier_name

/// Collection of common types used by face configs.
public enum CommonFaceConfig {

    /// Event triggers.
    public enum OnEvent: String {
        case start
        case state
        case click
        case animationStart = "animation-start"
        case animationComplete = "animation-complete"
        case actionComplete = "action-complete"
        case actionFail = "action-fail"
    }

    public struct TriggerRule: Equatable, Hashable {

        public let on: String
        public let play: String?
        public let target: String?
        public let value: JSON?
        public let delay: Double
        public let sound: SoundEffect?
        public let action: ActionEffect?

        init(descriptor: JSON) throws {
            guard
                let _on = descriptor["on"]?.stringValue else {
                    throw NSError()
            }
            self.on = _on
            self.play = descriptor["play"]?.stringValue
            self.target = descriptor["target"]?.stringValue
            self.value = descriptor["value"]
            self.delay = descriptor["delay"]?.doubleValue ?? 0
            if let soundDescriptor = descriptor["sound"] {
                self.sound = try SoundEffect(descriptor: soundDescriptor)
            } else {
                self.sound = nil
            }
            if let actionDescriptor = descriptor["action"] {
                self.action = try ActionEffect(descriptor: actionDescriptor)
            } else {
                self.action = nil
            }
        }

        public struct SoundEffect: Equatable, Hashable {
            public let resourceName: String
            public let volume: Float
            public let isPositional: Bool

            init(descriptor: JSON) throws {
                guard let _resourceName = descriptor["resource_name"]?.stringValue else {
                    throw NSError()
                }
                self.resourceName = _resourceName
                self.volume = Float(descriptor["volume"]?.doubleValue ?? 1.0)
                self.isPositional = descriptor["is_positional"]?.boolValue ?? false
            }
        }

        public struct ActionEffect: Equatable, Hashable {
            public let name: String
            public let payload: JSON?
            public let modify: JSON?

            init(descriptor: JSON) throws {
                guard let _name = descriptor["name"]?.stringValue else {
                    throw NSError()
                }
                self.name = _name
                self.payload = descriptor["payload"]
                self.modify = descriptor["modify"]
            }
        }

    }

}
