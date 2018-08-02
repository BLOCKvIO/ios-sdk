//
//  FaceManager.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/08/01.
//

import Foundation


/*
 This enum lives viewer-side - only the string values are passed through.
 */
/// Models the visual context in which the vAtom is being presented.
enum ViewContext: String {
    case glyf
    case icon
    case activated
    case fullscreen
    case card
}

/// Models the face view modes supported by the server.
enum ViewMode: String {
    case icon
    case card
    case fullscreen
    case activated
}

protocol FaceSelector {
    
    typealias ServerViewMode = String // this is a strict mapping to the server view mode
    typealias routine = ([FaceModel], ViewMode) -> FaceModel
    
    /// This is an extension point for the viewer to customize the face ranking.
    var customRoutine: ([FaceModel], ServerViewMode) -> FaceModel { get set }
    
    // MARK: - Face Selection
    
    /// auto-select a best face
    /// similar to what we do in the generic viewer with fallbacks for missing faces
    /// this will require a pre built (default) selection routine
    func selectBestFace(forViewMode: ServerViewMode, faces: [FaceModel]) -> FaceModel?
    
    /// get the face for the view mode, or `nil` if not available
    ///
    /// this is basically a filter to get one face (if it exisits)
    func faceForViewMode(viewMode: ServerViewMode, faces: [FaceModel]) -> FaceModel?
    
    
    /*
     Face selection ONLY validates:
     1. The native face code is installed in app.
     2. The platform is supported.
     3. The view mode matches the visual context.
     4. If there are multiple, select the first.
     
     Face selection does NOT validate:
     1. Vatom private properties
     2. Vatom resources
     
     This is left to the face code to validate and display an error.
     */
    
    /// get the face for a custom routine
    func selectFace(routine: routine, viewMode: ViewMode, faces: [FaceModel]) -> FaceModel?
    
    
    


}


//class FaceManager: FaceSelector {
//
//    func rank(face: FaceModel) -> Int {
//        // return the face's ranking
//
//        /*
//         Default ranking:
//
//         1.
//
//         */
//
//    }
//
//}
