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

/// Protocol for all faces to adopt.
///
/// This is the base protocol and defines the base of what it means to be a face (native or web).
///
/// Face creators will begin by implementing this protocol on a UIView.
public protocol FaceView where Self: UIView {

    // MARK: - Properties

    /// Uniqiue identifier of the native face.
    var displayURL: String { get }

    /*
     Architecture
     
     Another option to having a vatomPack is to have a refrence to VatomView. This may eliminate copies
     (although with COW it shouldn't be an issue).
     */

    /// Vatom pack for display.
    var vatomPack: VatomPackModel { get set }

    /// Selected face model.
    var selectedFace: FaceModel { get set }

    /// Face selection procedure.
    var procedure: FaceSelectionProcedure { get set }

    // MARK: - Lifecycle

    /// Called
    func onLoad(completed: () -> Void, failed: Error?)

    /// Called when the vatom pack is updated.
    ///
    /// This may be called in response to numerous events.
    ///
    /// E.g. A vAtom's root or private section are updated and the signal come down via the Web socket.
    func onVatomUpdated(_ vatomPack: VatomPackModel)

    /// Called
    func onUnload()

}
