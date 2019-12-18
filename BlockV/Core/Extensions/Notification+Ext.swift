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

/// Extension containing internal notifications.
extension Notification.Name {

    internal struct BVInternal {
        /// INTERNAL: Broadcast to indicate user authorization is required.
        internal static let UserAuthorizationRequried = Notification.Name("com.blockv.internal.user.auth.required")
    }

}

/// Extension containing external notifications.
public extension Notification.Name {

    struct BVAction {
        public static let willPerformAction = Notification.Name("com.blockv.action.will.perform")
        public static let didPerformAction = Notification.Name("com.blockv.action.did.perform")
    }

}

