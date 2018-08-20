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
 
 > Rather, such errors are left to the face code to validate and display an error.
 */





// ------------------------------------

/// Pack model holding a single vatom and its associated faces and actions.
struct VatomPackModel {
    let vatom: VatomModel
    let faces: [FaceModel] = []
    let actions: [ActionModel] = []
    
    //TODO: The init may need to be private to prevent the viewer from init-ing this struct with arbitrary and unrelated
    // vatom, actions, or faces.
}

// ------------------------------------

/*
 Questions:
 
 1. What view must be shown when the selection procedure fails to select a face?
 > See outcomes - show error with actiavted image.
 2. Should their be a fallback, like show the native image face?
 > No, show error.
 3. Should we allow vatom view to be instantiated directly using a face (i.e. without using a selection procedure)?
    > Maybe someone creates a viewer and only wants to add 2 faces to each of their vAtoms.
    > How are we going to enfore that people add a 'minimum reasonable faces'?
 */

/// Responsible for displaying a vAtom face (native or Web).
class VatomView: UIView {

    // MARK: - Properties

    var selectedFace: FaceModel? //FIXME: What should be displayed if a face is not selected?
    var selectedFaceView: UIView? //FIXME: What type should this be?

    var loadingView: UIView?
    var errorView: UIView?

    /// The vatom pack.
    var vatomPack: VatomPackModel {
        didSet {
            // Run the Face View Lifecycle (FVLC).
            runFaceViewLifecylce()
        }
    }
    
    /// The face selection procedure.
    ///
    /// Viewers may wish to update the procedure in reponse to certian events.
    ///
    /// For example, if the viewer may wish to change the procedure from 'icon' to 'activated' while the VatomView is
    /// on screen.
    var procedure: FaceSelectionProcedure {
        didSet {
            // Run the Face View Lifecycle (FVLC).
            runFaceViewLifecylce()
        }
    }
    
    // MARK: - Web Socket
    
    // TODO: Respond to the Web socket, pass events down to the Face View.
    
    

    // MARK: - Initializer

    /// Creates a vAtom view for the specifed vAtom.
    ///
    /// - Parameters:
    ///   - vatomPack: The vAtom to display and its associated faces and actions.
    ///   - faces: The array of faces associated with the vAtom's template.
    ///   - actions: The array of actions associated with the vAtom's template.
    ///   - procedure: An embedded (predefiened) face selection procedure that determines which face to display.
    init(vatomPack: VatomPackModel, procedure: StoredProcedure) {
        
        self.vatomPack = vatomPack
        self.procedure = procedure.selectionProcedure
        
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

    }

    /// Creates a vAtom view for the specifed vAtom using the provided face selection procedure.
    ///
    /// - Parameters:
    ///   - vatom: The vAtom to display.
    ///   - faces: The array of faces associated with the vAtom's template.
    ///   - actions: The array of actions associated with the vAtom's template.
    ///   - customProcedure: A function type that allows for customization of the face selection.
    init(vatomPack: VatomPackModel,
         customProcedure: @escaping FaceSelectionProcedure) {
        
        self.vatomPack = vatomPack
        self.procedure = customProcedure
        
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        
        self.loadingView = UIView() // or custom
        self.errorView = UIView() // or custom
        
    }

    // MARK: - Methods
    
    func runFaceViewLifecylce() {
        
        if let selectedFace = procedure(self.vatomPack.vatom, self.vatomPack.actions, self.vatomPack.faces) {
            print(selectedFace)
            // Create and show face
        } else {
            // Display the error view (which shows the activated image).
        }
        
    }

}
