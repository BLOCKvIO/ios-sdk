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

/// Models the embedded face selection procedures. A packaged procedure is a routine.
///
/// It important to think of these cases simply as unique identifiers of embedded (pre-built) face selection procedures.
///
/// Cases loosely map to the server's 'view_mode' only because the view mode is generally the predominant selection
/// criteria.
public enum FaceRoutine: String {
    
    case icon
    case activated
    case fullscreen
    case card
    case background
    
    /// Specifies the fallback face routine if the original face routine does not find a suitable FaceModel.
    var fallback: FaceRoutine? {
        switch self {
        case .icon:         return nil
        case .activated:    return .icon
        case .fullscreen:   return .icon
        case .card:         return .fullscreen
        case .background:   return nil
        }
    }
    
    // default selection procedure (lambda function)
    static let defaultProcedure: FaceSelector.FaceSelectionProcedure = { (faceModels, constraints) in
        
        var bestFace: FaceModel? = nil
        var bestRank = 0
        
        for face in faceModels {
            
            var rank = -1
            
            // ensure the 'view mode' is supported
            if face.properties.constraints.viewMode != constraints.viewMode {
                rank = -1
                continue
            }
            
            // rank 'ios' faces over 'generic'
            if face.properties.constraints.platform == "ios" {
                rank += 2
            } else if face.properties.constraints.platform == "generic" {
                rank += 1
            } else {
                rank = 1
                continue
            }
            
            // rank 'native' over 'web'
            if face.isNative {
                rank += 1
            }
            
            // compare to best rank
            if rank > bestRank {
                bestRank = rank // update rank
                bestFace = face // update best face
            }
            
        }
        
        return bestFace
        
    }
    
}

struct EmbeddedRoutines {
    
    // Specializations of the default routine
    
    static let iconProcedure: FaceSelector.FaceSelectionProcedure = { (faceModels, _) in
        FaceRoutine.defaultProcedure(faceModels, FaceSelector.FaceConstraints(viewMode: "icon"))
    }

    static let activatedProcedure: FaceSelector.FaceSelectionProcedure = { (faceModels, _) in
        FaceRoutine.defaultProcedure(faceModels, FaceSelector.FaceConstraints(viewMode: "icon"))
    }
    
    static let fullscreenProcedure: FaceSelector.FaceSelectionProcedure = { (faceModels, _) in
        FaceRoutine.defaultProcedure(faceModels, FaceSelector.FaceConstraints(viewMode: "activated"))
    }
    
    static let cardProcedure: FaceSelector.FaceSelectionProcedure = { (faceModels, _) in
        FaceRoutine.defaultProcedure(faceModels, FaceSelector.FaceConstraints(viewMode: "fullscreen"))
    }
    
    static let backgroundProcedure: FaceSelector.FaceSelectionProcedure = { (faceModels, _) in
        FaceRoutine.defaultProcedure(faceModels, FaceSelector.FaceConstraints(viewMode: "card"))
    }
    
}
