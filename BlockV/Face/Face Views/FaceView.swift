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

/// FIXME: This operator has a drawback in that it always makes an assignment.
infix operator ?=
internal func ?=<T> (lhs: inout T, rhs: T?) {
    lhs = rhs ?? lhs
}

/// Composite type that all face views must adopt.
public typealias FaceView = BaseFaceView & FaceViewLifecycle & FaceViewIdentifiable

public protocol FaceViewIdentifiable {

    /// Uniqiue identifier of the face.
    ///
    /// This id is used to register the face in the face registry. The face registry is an input to the
    /// `FaceSelectionProcedure` type.
    static var displayURL: String { get }

}

/// The protocol that face views must conform to.
public protocol FaceViewLifecycle: class {

    // MARK: - Lifecycle

    /// Called to initiate the loading of the face code.
    ///
    /// This should trigger the downloading of all necessary face resources.
    func load(completion: ((Error?) -> Void)?)

    /// Called when the vatom pack is updated.
    ///
    /// This may be called in response to numerous events.
    ///
    /// E.g. A vAtom's root or private section are updated and the signal come down via the Web socket state update.
    func vatomUpdated(_ vatom: VatomModel)

    /// Called when the face view is no longer being displayed.
    ///
    /// The face view should perform a clean up operation, e.g. cancel all downloads, remove any listers, nil out any
    /// reference and prepare for deallocation.
    func unload()

    /// Array of resources uses by this face.
    ///
    /// Use this function when prefetching resources for a face view.
    /// Extracts resources after the config section has been populated.
    ///func resourcesForPrefetch() -> [URL]

}

/// Abstract class all face views must derive from.
open class BaseFaceView: UIView {

    /// Vatom for display.
    public internal(set) var vatom: VatomModel

    /// Selected face model.
    public internal(set) var faceModel: FaceModel

    /// Initializes a BaseFaceView.
    public required init(vatom: VatomModel, faceModel: FaceModel) {
        self.vatom = vatom
        self.faceModel = faceModel
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
