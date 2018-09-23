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

/// Composite type that all face views must derive from and conform.
public typealias FaceView = BaseFaceView & FaceViewLifecycle & FaceViewIdentifiable

/// The protocol that face view must adopt to be uniquely identified.
public protocol FaceViewIdentifiable {

    /// Uniqiue identifier of the face view.
    ///
    /// This id is used to register the face in the face registry. The face registry is an input to the
    /// `FaceSelectionProcedure` type.
    static var displayURL: String { get }

}

/// The protocol that face views must adobt to receive lifcyle events.
public protocol FaceViewLifecycle: class {

    /// Called to initiate the loading of the face view.
    ///
    /// Face views should call the completion handler at once the face view has displayable content. Displayable content
    /// means a *minimum first view*. The face view may continue loading content after calling the completion handler.
    func load(completion: ((Error?) -> Void)?)

    /// Called when the vatom is updated.
    ///
    /// This may be called in response to numerous system events. Action handlers, brain code, etc. may all affect the
    /// vAtom's root or private section. Face view may need to update their content in response.
    func vatomUpdated(_ vatom: VatomModel)

    /// Called when the face view is no longer being displayed.
    ///
    /// The face view should perform a clean up operation, e.g. cancel all downloads, remove any listers, nil out any
    /// references and prepare for deallocation.
    func unload()

}

/// Abstract class all face views must derive from.
open class BaseFaceView: UIView {

    /// Vatom to use during rendering.
    public internal(set) var vatom: VatomModel

    /// Face model to be rendered.
    public internal(set) var faceModel: FaceModel

    /// Initializes a BaseFaceView using a vatom and a face model.
    public required init(vatom: VatomModel, faceModel: FaceModel) {
        self.vatom = vatom
        self.faceModel = faceModel
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
