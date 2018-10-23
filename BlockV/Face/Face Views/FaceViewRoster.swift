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

/// Unique identifier of the face view.
public typealias DisplayURL = String
/// Dictionary mapping display urls to `FaceView` types.
public typealias Roster = [DisplayURL: FaceView.Type]

/// A class that manages a roster of face views.
///
/// Face views are the mechanism by which a vAtom's face models are visualized. Typically, publishers register a number
/// of face models agaist a vAtom's parent template in order to target a wide range of viewer apps and platforms. The
/// decision then as to which of the face models can/should be rendered is dependent on the viewer app. Central to this
/// decision is whether the viewer app has an *installed* face view capable of *rendering* a face model using a face
/// view.
///
/// ### Usage
///
/// Face view are installed by registering them with the `FaceViewRoster` using the `register(:)` method. This should
/// done shortly after app launch.
///
///
/// ### Embedded Face Views
///
/// On initialization, a set of *embedded* face views (supported by BLOCKv) are registered on your behalf. The
/// registration of a custom face view where the `displayURL` matches an already registered face view will result in a
/// face view overwrite.
///
/// Embedded:
///
/// - Image Face: `native://image`
public class FaceViewRoster {

    // MARK: - Properties

    /// The shared face view roster.
    public static let shared: FaceViewRoster = {
        let roster = FaceViewRoster()
        // embedded face views
        roster.register(ImageFaceView.self)
        roster.register(ProgressImageFaceView.self)
        return roster
    }()

    /// Dictionary of registered face views.
    public private(set) var roster: Roster = [:]

    // MARK: - Methods

    /// Registers a class for use in creating new face views.
    ///
    /// - Parameter faceView: Class for creating face views.
    public func register(_ faceView: FaceView.Type) {
        roster[faceView.displayURL] = faceView
    }

}
