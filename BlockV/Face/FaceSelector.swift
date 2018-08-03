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

 Concept: Face Routine
 
 A face selection routine is the procedure used to select a face model from the potentially many templates faces
 associated with a vatom.
 
 Since vatoms rarely define the exact face they wish to show (because the faces that get registered against the vatom's
 template are out of the developers control).
 
 A face routine allows for 2 things:
 1. The best face can be chosen from the attributes and contrains of the available faces.
 2. A fallback face can be provided (in the event no face meets the criteria).
 
 
 Face selection routines ONLY validate:
 1. The native face code is installed.
 2. The platform is supported.
 3. The constrians, e.g. view mode are satisfied.
 
 > If there are multiple, select the first.
 
 Face selection routines do NOT validate:
 1. Vatom private properties
 2. Vatom resources
 
 > This is enforced becuase routines don't have context of the vatom.
 > Rather, such errors are left to the face code to validate and display an error.
 */

// i would prefer this class to be callled a face selector
public struct FaceSelector {
    
    //public typealias SelectionRoutine = ([FaceModel]) -> FaceModel?
    
    /// Collection of face constraints.
    ///
    /// Face constraints are supplied by the viewer. Only the viewer knows the constraints of the visual context in
    /// which the vAtom is being displayed.
    struct FaceConstraints {
        /// The view_mode of the face.
        let viewMode: String
        // let quality: String
        // let bluetooth: Bool
    }
    
    /// A face selection procedure takes, as input, an array of face models and a set of face constraints. As output,
    /// it return a face model which satisfies all supplied contraints, or `nil` if no satisfactory face was found.
    typealias FaceSelectionProcedure = (_ faceModels: [FaceModel], _ constraints: FaceConstraints) -> FaceModel?

    // MARK: - Properties

    /// Dictionary of embedded face selection routines for each face routine.
    ///
    /// Embedded routines are the face selection routines shipped with the SDK.
    private var embeddedProcedures: [FaceRoutine: FaceSelectionProcedure] = [:]
    
    // MARK: - Initialisation

    init() {

        embeddedProcedures[.icon]       = EmbeddedRoutines.iconProcedure
        embeddedProcedures[.activated]  = EmbeddedRoutines.activatedProcedure
        embeddedProcedures[.fullscreen] = EmbeddedRoutines.fullscreenProcedure
        embeddedProcedures[.card]       = EmbeddedRoutines.cardProcedure
        embeddedProcedures[.background] = EmbeddedRoutines.backgroundProcedure

    }

    // MARK: - Methods
    
    /// Returns the face selection routine associated with the routine id.
    func selectionProcedure(forFace faceRoutine: FaceRoutine) -> FaceSelectionProcedure {
        return self.embeddedProcedures[faceRoutine]! // FIXME: Remove force unwrap.
    }

    // MARK: - Face Model Selection

    /// Selects a face based on an exisiting face routine.
    func selectFace(fromFaceModels faceModels: [FaceModel], usingRoutine faceRoutine: FaceRoutine) -> FaceModel? {

        // look up the routine in the dictionary
        //let routine = embeddedProcedures[faceModels]

    }

    /// Selects a face using a custom selection routine.
    func selectFace(fromFaceModels faceModels: [FaceModel], usingRoutine selectionRoutine: SelectionRoutine) -> FaceModel? {

        // look up the routine in the dictionary
        return nil

    }

    // MARK: - 

}
