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

public typealias DisplayURL = String

public typealias FaceViewRoster = [DisplayURL: FaceView.Type]

/// This class is a registry for Face Views.
///
/// VatomView uses the registry's roster when determining which face model to select. The roster provides information
/// to VatomView about which face views are registered (i.e. able to display a vAtom).
///
/// The internal `roster` holds map of FaceView's keyed by their display URL.
///
/// On initialization, BLOCKv embedded faces are registered (i.e. stored in the roster).
/// Viewers may register custom Face Views using the `register` method.
///
/// - important:
/// The registration of a custom face view where the `displayURL` matches an already registered face view will result
/// in an overwrite.
public class FaceViewRegistry {
    
    // MARK: - Properties
    
    public static let shared: FaceViewRegistry = {
        let registry = FaceViewRegistry()
        
        //TODO: Add embedded faces
        
        return registry
    }()
    
    /// Dictionary of face
    public private(set) var roster: FaceViewRoster = [:]
    
    // MARK: - Methods
    
    public func register(_ faceView: FaceView.Type) {
        roster[faceView.displayURL] = faceView
    }
    
}
