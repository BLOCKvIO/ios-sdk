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
public struct VatomPackModel {
    public let vatom: VatomModel
    public let faces: [FaceModel] = []
    public let actions: [ActionModel] = []
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

    var selectedFace: FaceModel?
    var selectedFaceView: FaceView?

    var loadingView: UIView?
    var errorView: UIView?

    /// The vatom pack.
    var vatomPack: VatomPackModel {
        didSet {
            // run face view lifecycle (FVLC).
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
            // run face view lifecycle (FVLC).
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
    ///   - procedure: An embedded (predefiened) face selection procedure (FSP) that determines which face to display.
    init(vatomPack: VatomPackModel, procedure: EmbeddedProcedure) {

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
    ///   - customProcedure: A function type that allows for a custom face selection procedure (FSP).
    init(vatomPack: VatomPackModel, procedure: @escaping FaceSelectionProcedure) {

        self.vatomPack = vatomPack
        self.procedure = procedure

        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {

        self.accessibilityIdentifier = "id_vatomView"
        self.loadingView = UIView() // or custom
        self.errorView = UIView() // or custom

    }

    // MARK: - Methods

    /// Exectues the Face View Lifecycle
    ///
    /// 1. Run face selection procedure
    /// 2. Create face view
    /// 3. Inform the face view to load it's content
    /// 4. Display the face view
    func runFaceViewLifecylce() {

        let supportedDisplayURLS: Set = ["native://image"]

        if let selectedFace = procedure(self.vatomPack, supportedDisplayURLS) {
            print(selectedFace)

            // 1. Find face model's generator
            // 2. Call validate on the face code to see if the vatom meets the face code's requirements
            // 3. Init face view
            // 4. call onLoad(completion:)

        } else {
            // Display the error view (which shows the activated image).
        }

    }

}
