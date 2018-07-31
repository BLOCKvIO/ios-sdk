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

// I guess VatomView should conform to FacePresenter?

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
    
    var vatom: VatomModel!
    var faces: FaceModel!
    
    func vatomUpdated() {
        
        //TODO: how should the vatom view respond?
        
    }
    
    
    //TODO Init
    // 1. Pass in a face for display.
    // 2. Pass in an array of faces that a routine must choose from.
    
}

struct FaceRoutine {
    
    typealias ViewMode = String
    
    var routine: ([FaceModel], ViewMode) -> FaceModel
    
//    func selectBestFace() -> FaceModel {
//        
//        
//        
//    }
    
    func selectBestFace(faces: [FaceModel]) -> FaceModel {
        
        let rankings = faces.map { rankFace($0) }
        let max = rankings.max()
        let faceRanks = Array(zip(faces, rankings))
        
        
    }
    
    /// Ranks the face
    func rankFace(_ face: FaceModel) -> Int {
        
        var rank: Int = 0
        
        // prefer native faces over web
        if face.properties.displayURL.absoluteString.hasPrefix("native://") {
            
            //TODO: Check if the native face has a view generator.
            
            rank += 1
        }
        
        // prefer ios over generic
        if face.properties.constraints.platform.caseInsensitiveCompare("ios") == .orderedSame {
            rank += 1 // preferred
        } else if face.properties.constraints.platform.caseInsensitiveCompare("generic") == .orderedSame {
            rank += 0 // fallback
        } else {
            return -1 // do not use
        }
        
        return rank
        
    }
    
}
