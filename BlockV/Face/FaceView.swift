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

/// The protocol that native face views must conform to.
public protocol FaceView where Self: UIView {

    // MARK: - Properties

    /// Uniqiue identifier of the native face.
    var displayURL: String { get }

    /// Vatom pack for display.
    var vatomPack: VatomPackModel { get set }

    /// Selected face model.
    var selectedFace: FaceModel { get set }

    // MARK: - Lifecycle

    /// Called to initiate the loading of the face code.
    ///
    /// This should trigger the downloading of all necessary face resources.
    func load(completion: (Error?) -> Void)

    /// Called when the vatom pack is updated.
    ///
    /// This may be called in response to numerous events.
    ///
    /// E.g. A vAtom's root or private section are updated and the signal come down via the Web socket state update.
    func vatomUpdated(_ vatomPack: VatomPackModel)

    /// Called
    func unload()

}
