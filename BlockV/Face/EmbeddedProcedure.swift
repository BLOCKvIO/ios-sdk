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
 Goals:
 1. Vatom View will ask for the best face (default routine for each view context).
 2. Viewer's must be able to use pre-defined routines.
 3. Viewer's must be able supply a custom face selection procedure.
 
 Concept: Face Selection Procedure
 
 A face selection procedure is an algorithm used to select a face model from the (potentially) many faces
 associated with the vatom's template.
 
 Since vatoms rarely define the exact face they wish to show (because the faces that get registered against the vatom's
 template are out of the developers control).
 
 A face selection procedure allows for 2 things:
 1. The best face can be chosen from the attributes and contraints of the available faces.
 2. A fallback face can be provided (in the event no face meets the criteria).
 
 
 Face selection procedures ONLY validate:
 1. The native face code is installed.
 2. The platform is supported.
 3. The constrians, e.g. view mode are satisfied.
 
 > If there are multiple, select the first.
 
 Face selection routines do NOT validate:
 1. Vatom private properties
 2. Vatom resources
 
 > This is enforced becuase procedures don't have context of the vatom.
 > Rather, such errors are left to the face code to validate and display an error.
 */

// MARK: - Typealias

/// embedded procedure has known contraints - thus constraints don't need to be passed in.

/// Closure that determines which face model to use.
///
/// - Parameters:
///   - vatom: The vatom whose faces are to be selected.
///   - actions: The
typealias FaceSelectionProcedure = (_ vatom: VatomModel?, _ actions: [ActionModel]?, _ faces: [FaceModel])
    -> FaceModel?

// MARK: -

/// Models the embedded face selection procedures.
///
/// It important to think of these cases simply as unique identifiers of embedded (pre-built) face selection procedures.
///
/// Cases loosely map to the server's 'view_mode' only because the view mode is generally the predominant selection
/// criteria.
public enum EmbeddedProcedure: String {

    case icon
    case activated
    case fullscreen
    case card
    case background

    /// Collection of face selection constraints.
    ///
    /// These constraints are used as the selection criteria when choosing the best face for this procedure.
    struct SelectionConstraints {
        /// The view_mode of the face.
        let viewMode: String
        // let quality: String
    }

    /// A face selection procedure takes, as input, an array of face models and a set of face constraints. As output,
    /// it return a face model which satisfies all supplied contraints, or `nil` if no satisfactory face was found.
    ///
    /// - Parameters:
    ///   - faceModels: Array of face models to be used by the selection procedure.
    ///   - constraints: Struct holding face contraints to be used by the selection procedure.
    typealias EmbeddedFaceSelectionProcedure = (_ faceModels: [FaceModel], _ constraints: SelectionConstraints)
        -> FaceModel?

    /// Constraints associated with this embedded procedure.
    ///
    /// Returns the constrains for this embedded procedure.
    var constraints: SelectionConstraints {
        return SelectionConstraints(viewMode: self.rawValue)
    }

    //FIXME: Not yet used.
    /// Specifies the fallback face procedure if the original face procedure does not find a suitable FaceModel.
    var fallback: EmbeddedProcedure? {
        switch self {
        case .icon:         return nil
        case .activated:    return .icon
        case .fullscreen:   return .icon
        case .card:         return .fullscreen
        case .background:   return nil
        }
    }

    /// Default selection procedure.
    ///
    /// This closure defines a procedure that is common to most embedded procedures. Therefore, it makes
    /// sense to the logic in a central place.
    static let defaultSelectionProcedure: EmbeddedFaceSelectionProcedure = { (faceModels, constraints) in

        var bestFace: FaceModel?
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

    // MARK: - Face Selection

    /// Selects the best face using this procedure's defined face selection procedure and constraints.
    ///
    /// - Parameter faceModels: Array of face models to select from.
    /// - Returns: The best face, or `nil` if one is not found.
    func selectBestFace(from faceModels: [FaceModel]) -> FaceModel? {
        // pass in this procedure's constraints
        return EmbeddedProcedure.defaultSelectionProcedure(faceModels, self.constraints)
    }

}
