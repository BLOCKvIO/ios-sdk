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

public typealias FaceView = BaseFaceView & FaceViewInterface

/// The protocol that face views must conform to.
public protocol FaceViewInterface: class {
    
    // MARK: - Properties
    
    /// Uniqiue identifier of the face.
    ///
    /// This id is used to register the face in the face registry. The face registry is an input to the
    /// `FaceSelectionProcedure` type.
    static var displayURL: String { get }
    
    // MARK: - Lifecycle
    
    /// Called to initiate the loading of the face code.
    ///
    /// This should trigger the downloading of all necessary face resources.
    func load(completion: @escaping (Error?) -> Void)
    
    /// Called when the vatom pack is updated.
    ///
    /// This may be called in response to numerous events.
    ///
    /// E.g. A vAtom's root or private section are updated and the signal come down via the Web socket state update.
    func vatomUpdated(_ vatomPack: VatomPackModel)
    
    /// Called
    func unload()
    
}

open class BaseFaceView: UIView {
    
    /// Vatom pack for display.
    public var vatomPack: VatomPackModel
    
    /// Selected face model.
    public var faceModel: FaceModel
    
    public required init(vatomPack: VatomPackModel, faceModel: FaceModel) {
        self.vatomPack = vatomPack
        self.faceModel = faceModel
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

/*
 protocol P where Self : C {}
 In Swift 4.1 thi has some sharp edges
 https://stackoverflow.com/questions/50913244/swift-protocol-with-where-self-clause
 
 Maybe Swift 5 will allow a single procotol where the type of the superclass is constrained.
 The problem is when the type in instantiated from meta type. Eg.
 
 let type = SomeFaceView.type
 
 let a = type.init(vatomPack, faceModel) // error: there is some confusion wiht the required init.
 */

/// The protocol that face views must conform to.
public protocol FaceView2 where Self: UIView {
    
    // MARK: - Properties
    
    /// Uniqiue identifier of the face.
    ///
    /// This id is used to register the face in the face registry. The face registry is an input to the
    /// `FaceSelectionProcedure` type.
    static var displayURL: String { get }
    
    /// Vatom pack for display.
    var vatomPack: VatomPackModel { get set }
    
    /// Selected face model.
    var faceModel: FaceModel { get set }
    
    // Initialized with a vatomPack and the selected face model.
    init(vatomPack: VatomPackModel, faceModel: FaceModel)
    
    // MARK: - Lifecycle
    
    /// Called to initiate the loading of the face code.
    ///
    /// This should trigger the downloading of all necessary face resources.
    func load(completion: @escaping (Error?) -> Void)
    
    /// Called when the vatom pack is updated.
    ///
    /// This may be called in response to numerous events.
    ///
    /// E.g. A vAtom's root or private section are updated and the signal come down via the Web socket state update.
    func vatomUpdated(_ vatomPack: VatomPackModel)
    
    /// Called
    func unload()
    
}

public class SomeFaceView: UIView, FaceView2 {
    
    public static var displayURL: String = "native://some-face"
    
    public var vatomPack: VatomPackModel
    
    public var faceModel: FaceModel
    
    public required init(vatomPack: VatomPackModel, faceModel: FaceModel) {
        self.vatomPack = vatomPack
        self.faceModel = faceModel
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func load(completion: @escaping (Error?) -> Void) {
        print(#function)
    }
    
    public func vatomUpdated(_ vatomPack: VatomPackModel) {
        print(#function)
    }
    
    public func unload() {
        print(#function)
    }
    
}
