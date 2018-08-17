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

// ------------------------------------

/// Pack model holding a single vatom and its associated faces and actions.
struct VatomPackModel {
    let vatom: VatomModel
    let faces: [FaceModel]
    let actions: [ActionModel]
    
    //TODO: The init may need to be private to prevent the viewer from init-ing this struct with arbitrary and unrelated
    // vatom, actions, or faces.
    
}

// ------------------------------------

/*
 Questions:
 
 1. What view must be shown when the selection procedure fails to select a face?
 2. Should their be a fallback, like show the native image face?
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

    //TODO: This could become PackModel.
    var vatom: VatomModel!
    var faces: [FaceModel] = []
    var actions: [ActionModel] = []

    // MARK: - Initializer

    // Is this needed? What is the use case for supplying a face directly?

    init(vatom: VatomModel, face: FaceModel, actions: [ActionModel]) {

        // create a view with a known face
        selectedFace = face
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

    }

    /// Creates a vAtom view for the specifed vAtom.
    ///
    /// - Parameters:
    ///   - vatom: The vAtom to display.
    ///   - faces: The array of faces associated with the vAtom's template.
    ///   - actions: The array of actions associated with the vAtom's template.
    ///   - procedure: An embedded (predefiened) face selection procedure that determines which face to display.
    init(vatom: VatomModel,
         faces: [FaceModel],
         actions: [ActionModel],
         procedure: EmbeddedProcedure) {

        // select best face

        //FIXME: What happens if this fails?
        // Sould this be done on init? the procedure could be slow.
        selectedFace = procedure.selectBestFace(from: faces)

        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        print(selectedFace)

    }

    /// Creates a vAtom view for the specifed vAtom using the provided face selection procedure.
    ///
    /// - Parameters:
    ///   - vatom: The vAtom to display.
    ///   - faces: The array of faces associated with the vAtom's template.
    ///   - actions: The array of actions associated with the vAtom's template.
    ///   - customProcedure: A function type that allows for customization of the face selection.
    init(vatom: VatomModel,
         faces: [FaceModel],
         actions: [ActionModel],
         customProcedure: FaceSelectionProcedure) {

        selectedFace = customProcedure(faces) //FIXME: What happens if this fails?

        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        print(selectedFace)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {

        self.loadingView = UIView() // or custom
        self.errorView = UIView() // or custom

    }

    // MARK: - Methods

}
