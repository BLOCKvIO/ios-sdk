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

/*
 This could all move onto VatomView as a static? As long as the memory overhead of VatomView remains small.
 */

public typealias DisplayURL = String

public typealias FaceViewRoster = [DisplayURL: FaceView.Type]

public class FaceViewRegistry {

    // MARK: - Properties

    public static let shared = FaceViewRegistry()

    init() {
        // register embedded face views
        self.register(ImageFaceView.self)
        self.register(ImageSubclassFaceView.self)
        self.register(TestFaceView.self)
    }

    /// Dictionary of face
    public private(set) var roster: FaceViewRoster = [:]

    // MARK: - Methods

    public func register(_ faceView: FaceView.Type) {
        roster[faceView.displayURL] = faceView
    }

}
