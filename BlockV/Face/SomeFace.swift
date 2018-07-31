//
//  SomeFace.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/07/26.
//

import Foundation

/*
 Questions
 1. Should view mode be an emum? What if the server adds a new view_mode, does the SDK need to update?
 2.
 
 Generic Viewer
 1. Will VatomModel interop well with the Generic Viewer?
 2. Maybe the Generic Viewer should only use the core part of the SDK and not use the face module.
 */

/// Pack model holding a single vatom.
struct VatomPackModel {
    let vatom: VatomModel
    let faces: [FaceModel]
    let actions: [ActionModel]
}

/// Types that want to present a vAtom face should conform to this protocol.
protocol FacePresenter {
    var vatom: VatomModel { get set }
    var selectedFace: FaceModel { get set }
    var selectedFaceView: UIView { get set }
    var viewMode: String { get set }
}

/// Responsible for displaying a vAtom face (native or Web).
///
/// - Where to collect errors?
class VatomView: UIView {
    
    var vatom: VatomModel
    var faces: FaceModel
    
    func vatomUpdated() {
        
        //TODO: how should the vatom view respond?
        
    }
    
    init(vatomPackModel: VatomPackModel) {
        
        
    }
    
}

struct FaceRoutine {
    
    typealias ViewMode = String
    
    var routine: ([FaceModel], ViewMode) -> FaceModel
    
    func selectBestFace() -> FaceModel {
        
        
        
    }
    
}
