//
//  FaceManager.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/08/01.
//

import Foundation

protocol FaceManager {
    
    func selectFace(something: String, viewMode: String) -> FaceModel?
    
    /// This is an extension point for the viewer to customize the face ranking.
    var customRoutine: ([FaceModel], ViewMode) -> FaceModel { get set }

}


class FaceManager {
    
    func rank(face: FaceModel) -> Int {
        // return the face's ranking
        
        /*
         Default ranking:
         
         1.
         
         */
        
    }
    
}
