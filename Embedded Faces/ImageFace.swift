//
//  ImageFace.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/08/16.
//

/*
 This face should be in it's own repo?
 
 How will that work if the face is dependent on VatomModel and FaceModel?
 
 - 3rd party native faces will be in their own repo.
 - They will need to import the BLOCKv 
 
 */

import Foundation

protocol NativeFace {
    
    var generator: UIView { get }
    
}

/// Native image face
class ImageFace: UIView {
    
    var vatom: VatomModel //FIXME: this mean a dependency on BLOCKv
    let face: FaceModel //FIXME: this means a dependency on BLOCKv
    
    init(vatom: VatomModel, face: FaceModel) {
        
        self.vatom = vatom
        self.face = face
        
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Face View Lifecycle
    
    func onLoad(completed: () -> (), failed: () -> ()) {
        
        // ...
        
    }
    
    func onUnload() {
        
        // ...
        
    }
    
}
