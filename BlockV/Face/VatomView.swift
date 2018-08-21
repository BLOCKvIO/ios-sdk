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
public class VatomView: UIView {

    // MARK: - Properties

    var selectedFace: FaceModel?
    var selectedFaceView: FaceView?

    var loadingView: UIView?
    var errorView: UIView?

    /// The vatom pack.
    public var vatomPack: VatomPackModel? {
        didSet {
            // run FVLC
            runFaceViewLifecylce()
        }
    }

    /// The face selection procedure.
    ///
    /// Viewers may wish to update the procedure in reponse to certian events.
    ///
    /// For example, if the viewer may wish to change the procedure from 'icon' to 'activated' while the VatomView is
    /// on screen.
    public var procedure: EmbeddedProcedure? {
        didSet {
            // run FVLC
            runFaceViewLifecylce()
        }
    }

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

        precondition(vatomPack != nil, "Vatom Pack must not be nil")
        precondition(procedure != nil, "Procedure must not be nil")

        runFaceViewLifecylce()

    }

    // MARK: - Methods

    /// Exectues the Face View Lifecycle for a specific vatom.
    ///
    /// 1. Run face selection procedure
    /// 2. Create face view
    /// 3. Inform the face view to load it's content
    /// 4. Display the face view
    public func runFaceViewLifecylce() {

        // precondition that vatom pack and procedure have been set
        guard let vatomPack = vatomPack, let procedure = procedure else { return }

        //FIXME: Mocks the face registery.
        //FIXME: Need to decide how to register the web face (if at all).
        let faceRegistry: Set = ["web://",
                                 "native://image",
                                 "native://image-policy",
                                 "native://image-redeemable",
                                 "native://level-image"]

        // 1. select the best face
        guard let selectedFace = procedure.selectionProcedure(vatomPack, faceRegistry) else {
            // display the error view (which shows the activated image).
            return
        }
        self.selectedFace = selectedFace
        print("Selected face: \(selectedFace)")

        // 2. check if a new face model has been selected
        guard selectedFace != self.selectedFace else {
            // no change
            // maybe notify the face to redraw?
            return
        }

        // 3. find face model's generator
        //FIXME: This should be pulled from the face registry.
        let faceView = ImageFaceView(vatomPack: vatomPack, selectedFace: selectedFace)

        /*
         How do I know if the vAtom is loading?
         How do I know if a vAtom's resources are loading?

         Maybe the face view should inform the VatomView when the face is done loading? This way the VatomView knows
         when to show the loader, and then, when to show the face. This would work well as a delegate.
         
         */

        //FIXME: Will native and web hierarchys be different? Is there a need for this conditional flow?
        if selectedFace.isNative {

            // inset the face view self's view hierarcy
            self.selectedFaceView = faceView
            faceView.frame = self.bounds
            faceView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.insertSubview(faceView, at: 0)

        } else if selectedFace.isWeb {

        } else {
            // show some error
        }

        // > Call validate on the face code to see if the vatom meets the face code's requirements
        // 3. Init face view
        // 4. call onLoad(completion:)

    }

}
