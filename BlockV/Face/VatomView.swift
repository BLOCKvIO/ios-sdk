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

/*
 Questions:
 
 1. What view must be shown when the selection procedure fails to select a face?
 > See outcomes - show error with actiavted image.
 2. Should their be a fallback, like show the native image face?
 > No, show error.
 3. Should we allow vatom view to be instantiated directly using a face (i.e. without using a selection procedure)?
    > Maybe someone creates a viewer and only wants to add 2 faces to each of their vAtoms.
    > How are we going to enfore that people add a 'minimum reasonable faces'?
 
 - What if the FSP was a type rather than a function. That way each FSP could have a name, and therefore be identifiable
 by the VatomView and so have conditional logic run based on its name. Or, should the VatomView be 'unware' of the FSP
 and simply use what information the vatompack gives it?
 
 -
 
 */

/// Responsible for displaying a vAtom face (native or Web).
public class VatomView: UIView {

    // MARK: - Properties

    /*
     Both vatomPack and the procedure may be updated over the life of the vatom view.
     This means if either is updated, the VVLC should run.
     
     Either update may (or may not) result in the selectedFaceModel changing. If it does a full FaceView replacement is
     needed.
     
     If the vatomPack is updated, and the selectedFaceModel remains the same, then updates may (or may not) need to be
     passed down to the currently selected face view.
     
     How sould consumer set the vatomPack and procedure? Via one function?
     
     */

    /// The vatom pack.
    public private(set) var vatomPack: VatomPackModel?

    /// The face selection procedure.
    ///
    /// Viewers may wish to update the procedure in reponse to certian events.
    ///
    /// For example, the viewer may change the procedure from 'icon' to 'activated' while the VatomView is
    /// on screen.
    public private(set) var procedure: EmbeddedProcedure?

    /// Face model selected by the specifed face selection procedure (FSP).
    public private(set) var selectedFaceModel: FaceModel?

    /// Selected face view (function of the selected face model).
    public private(set) var selectedFaceView: FaceView?

    //FIXME: How is the consumer going to set the loading and error views?

    var loadingView: UIView?
    var errorView: UIView?

    // MARK: - Web Socket

    // TODO: Respond to the Web socket, pass events down to the face view, run FVLC.

    // MARK: - Initializer

    /// Creates a vAtom view for the specifed vAtom.
    ///
    /// - Parameters:
    ///   - vatomPack: The vAtom to display and its associated faces and actions.
    ///   - faces: The array of faces associated with the vAtom's template.
    ///   - actions: The array of actions associated with the vAtom's template.
    ///   - procedure: An face selection procedure (FSP) (either embedded or custom) that determines which face to
    ///     display.
    public init(vatomPack: VatomPackModel, procedure: EmbeddedProcedure) {

        self.vatomPack = vatomPack
        self.procedure = procedure

        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // caller must set vatom pack
        // caller must ser procedure

        commonInit()
    }

    /// Common initializer
    private func commonInit() {

        self.backgroundColor = UIColor.red.withAlphaComponent(0.3)

        self.loadingView = UIView() // or custom
        self.errorView = UIView() // or custom

        runVatomViewLifecylce()

    }

    // MARK: - Methods

    /// Updates the vatomPack and procedure. Triggers the Vatom View Lifecycle which may result in a new face view
    /// being shown.
    ///
    public func update(usingVatomPack vatomPack: VatomPackModel, procedure: EmbeddedProcedure) {

        self.vatomPack = vatomPack
        self.procedure = procedure

        runVatomViewLifecylce()

    }

    /// Exectues the Vatom View Lifecycle (VVLC) on the current vAtom pack.
    ///
    /// Called
    ///
    /// 1. Run face selection procedure
    /// > Compare the selected face to the current face
    /// 2. Create face view
    /// 3. Inform the face view to load it's content
    /// 4. Display the face view
    public func runVatomViewLifecylce() {

        //FIXME: Part of this could run on a background thread, e.g fsp

        precondition(vatomPack != nil, "vatomPack must not be nil.")
        precondition(procedure != nil, "procedure must not be nil.")

        // precondition that vatom pack is not nil
        guard let vatomPack = vatomPack else {
            return
        }

        // precondition that procedure is not nil
        guard let procedure = procedure else {
            return
        }

        // 1. select the best face model
        guard let selectedFace = procedure.selectionProcedure(vatomPack, faceRegistry) else {
            //FIXME: display the error view (which shows the activated image).
            return
        }

        printBV(info: "FSP selected face model: \(selectedFace)")

        // 2. check if the face model has not changed
        if selectedFace == self.selectedFaceModel {

            printBV(info: "Face model unchanged - Updating face view.")

            /*
             Although the selected face model has not changed, other items in the vatom pack may have, these updates
             must be passed to the face view to give it a change to update its state.
             
             The VVLC should not be re-run (since the selected face view does not need replacing).
             */

            // update currently selected face view (without replacement)
            self.selectedFaceView?.vatomUpdated(vatomPack)

            //FXIME: How does the face view find out what has changed? Maybe the vatomPack must have a 'diff' property?

        } else {

            printBV(info: "Face model change - Replacing face view.")

            //FIXME: Call validate on the face code to see if the vatom meets the face code's requirements

            //FIXME: This should be pulled from the face registry.
            // 3. find face model's face view generator
            let selectedFaceView = ImageFaceView(vatomPack: vatomPack, selectedFace: selectedFace)

            // relace currently selected face view with newly selected
            self.replaceFaceView(withFaceView: selectedFaceView)

        }

    }

    /// Replaces the current face view (if any) with the specified face view and starts the FVLC.
    ///
    /// Call this function only if you want a full replace of the current face view.
    ///
    /// Triggers the Face View Life Cycle (VVLC)
    func replaceFaceView<T: FaceView>(withFaceView newFaceView: T) {

        /*
         Options: This function could take in a FaceView instance, or take in a FaceView.Type and create the instance
         itself (using the generator)?
         */

        // update currently selected face view
        self.selectedFaceView = newFaceView

        // insert face view into the view hierarcy
        newFaceView.alpha = 0.000001 // hack to allow webview to load
        newFaceView.frame = self.bounds
        newFaceView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.insertSubview(newFaceView, at: 0)

        // 1. instruct face view to load its content
        newFaceView.load { (error) in

            printBV(info: "Face view load completion called.")

            // ensure no error
            guard error == nil else {
                // show error
                return
            }

            // show face
            // ...

        }

    }

    //FIXME: Mocks the face registery.
    //FIXME: Need to decide how to register the web face (if at all).
    let faceRegistry: Set = ["web://",
                             "native://image",
                             "native://image-policy",
                             "native://image-redeemable",
                             "native://level-image"]

}
