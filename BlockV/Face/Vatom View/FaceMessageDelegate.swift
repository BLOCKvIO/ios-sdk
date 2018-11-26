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

/// Face message error (view bridge).
public struct FaceMessageError: Error {
    public let message: String
    /// Initialise with a message. This message is forwarded to the Web Face SDK.
    public init(message: String) {
        self.message = message
    }
}

/// The protocol types must conform to in order to handle face messages.
///
/// Faces may send messages to their underlying viewer to request additional functionality. As a viewer it is
/// important that you state which messages you support (by implementing `determinedSupport(forFaceMessages:[Srting])`).
/// This gives the face an opportunity to adapt it's behaviour.
public protocol FaceMessageDelegate: class {

    /// Completion handler for face messages.
    ///
    /// - Parameters:
    ///   - payload: The JSON payload to be sent back to the Web Face SDK.
    ///   - error: Error with description if one was encountered.
    typealias Completion = (_ payload: JSON?, _ error: FaceMessageError?) -> Void

    /// Called when the vatom view receives a message from the face.
    ///
    /// - Parameters:
    ///   - vatomView: The `VatomView` instance which the face message was received from.
    ///   - message: The unique identifier of the message.
    ///   - object: Companion object which addtional information relevant to the request.
    ///   - completion: The completion handler to call once the request has been processed.
    func vatomView(_ vatomView: VatomView,
                   didRecevieFaceMessage message: String,
                   withObject object: [String: JSON],
                   completion: FaceMessageDelegate.Completion?)

}
