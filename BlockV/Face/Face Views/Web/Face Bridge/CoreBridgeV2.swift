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

/// Core Bridge (Version 2.0.0)
///
/// Bridges into the Core module.
class CoreBridgeV2: CoreBridge {

    // MARK: - Enums

    /// Represents the contract for the Web bridge (version 2).
    enum MessageName: String {
        case initialize         = "init"
        case getVatomChildren   = "vatom.children.get"
        case performAction      = "vatom.performAction"
        case getUserProfile     = "user.profile.fetch"
        case getVatom           = "vatom.get"
    }

    var faceView: FaceView?

    required init(faceView: FaceView) {
        self.faceView = faceView
    }

    func canProcessMessage(_ message: String) -> Bool {
        return true
        //TODO: Implement
    }

    func processMessage(_ scriptMessage: FaceScriptMessage, completion: @escaping CoreBridgeV2.Completion) {
        //TODO: Implement
    }

}
