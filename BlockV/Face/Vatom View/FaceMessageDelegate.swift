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
import GenericJSON

/// The protocol types must conform to in order to communinicate with vatom view.
///
/// Faces may send custom messages to their underlying viewer to request additional functionality.
public protocol VatomViewDelegate: class {

    /// Tells the delegate that a face message has been received.
    ///
    /// - Parameters:
    ///   - vatomView: A vatom-view object informing the delegate about the face message.
    ///   - message: The unique identifier of the message.
    ///   - object: Companion object which addtional information relevant to the request.
    ///   - completion: The completion handler to call once the request has been processed. Passed a `Result` type
    ///         with either the success payload of a face message error.
    func vatomView(_ vatomView: VatomView,
                   didRecevieFaceMessage message: String,
                   withObject object: [String: JSON],
                   completion: ((Result<JSON, FaceMessageError>) -> Void)?)

    /// Tells the delegate that a face view was selected, or an error was encountered.
    ///
    /// A face view is selected as part of the Vatom View Life Cycle (VVLC). There are two scenarios where this will
    /// happen:
    /// 1. A `VatomView` instance was created (triggering the VVLC).
    /// 2. After calling `update(usingVatom:procedure:)` (triggering the VVLC), which resulted in a new Face View being
    /// selected.
    ///
    /// - Parameters:
    ///   - vatomView: A vatom-view object informing the delegate about the selected face.
    ///   - result: A `Result` type type containing either the selected face view or an error.
    func vatomView(_ vatomView: VatomView, didSelectFaceView result: Result<FaceView, VVLCError>)

    /// Tells the delgate that the selected face view has completed loading, or an error was encountered.
    ///
    /// - Parameters:
    ///   - vatomView: A vatom-view object informing the delegate about the selected face completing its load.
    ///   - result: A `Result` instance with the result of the selected face view's load outcome.
    func vatomView(_ vatomView: VatomView, didLoadFaceView result: Result<FaceView, VVLCError>)

}

/// This extension contians default and empty implementations of `VatomViewDelegate` methods.
/// This is the 'Swifty' way to make the methods optional.
public extension VatomViewDelegate {

    func vatomView(_ vatomView: VatomView,
                   didRecevieFaceMessage message: String,
                   withObject object: [String: JSON],
                   completion: ((Result<JSON, FaceMessageError>) -> Void)?) {
        // optional method
    }

    func vatomView(_ vatomView: VatomView, didSelectFaceView result: Result<FaceView, VVLCError>) {
        // optional method
    }

    func vatomView(_ vatomView: VatomView, didLoadFaceView result: Result<FaceView, VVLCError>) {
        // optional method
    }

}

/// Vatom View Life Cycle error.
public enum VVLCError: Error, CustomStringConvertible {

    /// Face selection failed.
    case faceViewSelectionFailed
    /// A face model was selected but no corresponding face view was registered.
    case unregisteredFaceViewSelected(_ displayURL: String)
    /// The face view failed to load.
    case faceViewLoadFailed

    public var description: String {
        switch self {
        case .faceViewSelectionFailed:
            return "Face Selection Procedure (FSP) did not select a face view."
        case .unregisteredFaceViewSelected(let url):
            return """
            Face Selection Procedure (FSP) selected a face view '\(url)' without the face view being registered.
            """
        case .faceViewLoadFailed:
            return "Face View load failed."
        }
    }

}

// MARK: - Face View Delegate

/// Face message error (view bridge).
public struct FaceMessageError: Error {
    public let message: String
    /// Initialise with a message. This message is forwarded to the Web Face SDK.
    public init(message: String) {
        self.message = message
    }
}

/// The protocol face views must conform to in order to communicate
public protocol FaceViewDelegate: class {

    /// Called when the vatom view receives a message from the face.
    ///
    /// - Parameters:
    ///   - faceView: The face view from which this message was received.
    ///   - message: The unique identifier of the message.
    ///   - object: Companion object which addtional information relevant to the request.
    ///   - completion: The completion handler to call once the request has been processed.
    func faceView(_ faceView: FaceView,
                  didSendMessage message: String,
                  withObject object: [String: JSON],
                  completion: ((Result<JSON, FaceMessageError>) -> Void)?)

}
