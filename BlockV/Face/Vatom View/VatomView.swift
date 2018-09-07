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

/// Type that manage vAtom should conform to this delegate to know when the face has completed loading.
///
/// This is usefull when you only want to show a vatomview once it's completed loading.
protocol VatomViewLifecycleDelegte {

    /// Called when the vatom view's selected face view has loaded successful of with an error.
    func faceViewDidLoad(error: Error?)

    /*
     Additionally, the host would probably want to know more about the lifecycle of the vatom view.
     */

}

/*
 Goals:
 1. Vatom View will ask for the best face (default routine for each view context).
 2. Viewers must be able to use pre-defined procedures.
 3. Viewers must be able supply a custom face selection procedure.
 
 - Always defaults to the icon embedded FSP.
 - Always defaults to use the shared FaceRegistry roster.
 
 Face selection routines do NOT validate:
 1. Vatom private properties
 2. Vatom resources
 3. Vatom face model config
 > Rather, such errors are left to the face code to validate and display an error.
 */

/// Displays a face view for the specified vAtom.
///
/// The face displayed is dependent on the face selection procedure (FSP).
///
/// Loading and error views may be customized.
public class VatomView: UIView {

    // MARK: - Enum

    /// Models the Vatom View Lifecycle (VVLC) state.
    public enum LifecycleState {
        /// Lifecycle is busy or face view has not completed loading.
        case loading
        /// Lifecycle encountered an error
        case error
        /// Face view has successfully completed loading
        case completed
    }

    /// Tracks the VVLC state.
    public internal(set) var state: LifecycleState = .loading {
        didSet {
            switch state {
            case .loading:
                self.selectedFaceView?.alpha = 0.000001
                self.loadingView?.isHidden = false
                self.loadingView?.startAnimating()
                self.errorView?.isHidden = true
            case .error:
                self.selectedFaceView?.alpha = 0.000001
                self.loadingView?.isHidden = true
                self.loadingView?.stopAnimating()
                self.errorView?.isHidden = false

            case .completed:
                self.selectedFaceView?.alpha = 1
                self.loadingView?.isHidden = true
                self.loadingView?.stopAnimating()
                self.errorView?.isHidden = true
            }
        }
    }

    // MARK: - Properties

    /// The vatom to display.
    public internal(set) var vatom: VatomModel?

    /// The face selection procedure.
    ///
    /// Viewers may wish to update the procedure in reponse to certian events.
    ///
    /// For example, the viewer may change the procedure from 'icon' to 'engaged' while the VatomView is
    /// on screen.
    public internal(set) var procedure: FaceSelectionProcedure

    /// List of all the installed face views.
    ///
    /// The roster is a consolidated list of the face views registered by both the SDK and Viewer.
    public internal(set) var roster: FaceViewRoster

    /// Face model selected by the specifed face selection procedure (FSP).
    public private(set) var selectedFaceModel: FaceModel?

    /// Selected face view (function of the selected face model).
    public private(set) var selectedFaceView: FaceView? //(UIView & FaceView)?

    // MARK: Customization

    var loadingView: (UIView & FaceViewLoader)?
    var errorView: UIView?

    // TODO: Respond to the Web socket, pass events down to the face view, run FVLC.

    // MARK: - Initializer

    //FIXME: Should this class be allowed to be initialized with no params?

    /// Creates a vAtom view for the specifed vAtom.
    ///
    /// - Parameters:
    ///   - vatom: The vAtom to display (with its associated faces and actions).
    ///   - procedure: An face selection procedure (FSP) that determines which face to
    ///     display.
    public init(vatom: VatomModel,
                procedure: @escaping FaceSelectionProcedure = EmbeddedProcedure.icon.procedure) {

        self.vatom = vatom
        self.procedure = procedure
        self.roster = FaceViewRegistry.shared.roster

        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        commonInit()
        runVatomViewLifecylce()
    }

    required public init?(coder aDecoder: NSCoder) {

        self.procedure = EmbeddedProcedure.icon.procedure
        self.roster = FaceViewRegistry.shared.roster

        super.init(coder: aDecoder)

        // caller must set vatom model

        commonInit()
    }

    /// Common initializer
    private func commonInit() {

        self.loadingView = DefaultLoadingView(frame: self.bounds)
        loadingView!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(loadingView!)

        self.errorView = DefaultErrorView(frame: self.bounds)
        errorView!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(errorView!)
        self.state = .loading

    }
    
    // MARK: - Vatom View State Management
    
    /*
     Goals:
     - Viewers may want to manage the computation going on in a vatom view.
     these are messages FROM the host
     1. VVLC starts after calling start (not init).
     2. VVLC can be cancelled (to stop expensive resource downloading for example).
     */
    
    /// Starts the vatom view process (VVLC)
    func startLoad() {
        
    }
    
    /// Host may want to inform the face view to cancel loading. For example, cancel loading large resources etc.
    ///
    /// This is helpful in talbe view
    func cancelLoad() {
        
    }
    
    // part of this is the face view delegate (which send a message TO the host).
    
    // completed

    // MARK: - Methods

    /*
     Both vatom and the procedure may be updated over the life of the vatom view.
     This means if either is updated, the VVLC should run.
     
     Either update may (or may not) result in the selectedFaceModel changing. If it does a full FaceView replacement is
     needed.
     
     If the vatom is updated, and the selectedFaceModel remains the same, then updates may (or may not) need to be
     passed down to the currently selected face view.
     
     */

    public func update(usingVatom newVatom: VatomModel,
                       procedure: FaceSelectionProcedure? = nil) {

        // check for a vatom change
        if self.vatom?.id != newVatom.id {
            self.state = .loading
        }

        self.vatom = newVatom
        procedure.flatMap { self.procedure = $0 } // assign if not nil

        runVatomViewLifecylce()

    }

    /*
     Suggestion: Rename VVLC to Vatom View Routine (VVR)
     The lifecycle becomes the start, cancel, completed events.
     */
    
    /// Exectues the Vatom View Lifecycle (VVLC) on the current vAtom.
    ///
    /// 1. Run face selection procedure
    /// > Compare the selected face to the current face
    /// 2. Create face view
    /// 3. Inform the face view to load it's content
    /// 4. Display the face view
    public func runVatomViewLifecylce() {

        //FIXME: Part of this could run on a background thread, e.g fsp

        precondition(vatom != nil, "vatom must not be nil.")

        guard let vatom = vatom else { return } //FIXME: Show error?

        // 1. select the best face model
        guard let selectedFaceModel = procedure(vatom, Set(roster.keys)) else {

            printBV(error: "Face Selection Procedure (FSP) returned without selecting a face model.")
            self.state = .error
            //FIXME: display the error view (which shows the activated image).
            return
        }

        printBV(info: "Face Selection Procedure (FSP) selected face model: \(selectedFaceModel)")

        // 2. check if the face model has not changed
        if selectedFaceModel == self.selectedFaceModel {

            printBV(info: "Face model unchanged - Updating face view.")

            /*
             Although the selected face model has not changed, other items in the vatom may have, these updates
             must be passed to the face view to give it a change to update its state.
             
             The VVLC should not be re-run (since the selected face view does not need replacing).
             */

            self.state = .completed
            // update currently selected face view (without replacement)
            self.selectedFaceView?.vatomUpdated(vatom)

            //FXIME: How does the face view find out what has changed? Maybe the vatom must have a 'diff' property?

        } else {

            printBV(info: "Face model change - Replacing face view.")

            // replace currently selected face model
            self.selectedFaceModel = selectedFaceModel

            // 3. find face view type
            guard let faceViewType = roster[selectedFaceModel.properties.displayURL] else {
                // viewer developer MUST have registered the face view with the face registry
                assertionFailure(
                    """
                    Face selection procedure (FSP) selected a face without the face view being installed. Your FSP
                    MUST check if the face view has been registered with the FaceRegistry.
                    """)
                return
            }

            printBV(info: "Face view for face model: \(faceViewType)")

            //let faceViewType = FaceViewRegistry.shared.roster["native://image"]!
            //let selectedFaceView: FaceView = ImageFaceView(vatom: vatom, faceModel: selectedFace)
            let selectedFaceView: FaceView = faceViewType.init(vatom: vatom,
                                                               faceModel: selectedFaceModel)

            // relace currently selected face view with newly selected
            self.replaceFaceView(with: selectedFaceView)

        }

    }

    /// Replaces the current face view (if any) with the specified face view and starts the FVLC.
    ///
    /// Call this function only if you want a full replace of the current face view.
    ///
    /// Triggers the Face View Life Cycle (VVLC)
    func replaceFaceView(with newFaceView: (FaceView)) {

        /*
         Options: This function could take in a FaceView instance, or take in a FaceView.Type and create the instance
         itself (using the generator)?
         */

        self.state = .loading

        // update currently selected face view
        self.selectedFaceView = newFaceView

        // insert face view into the view hierarcy
        newFaceView.frame = self.bounds
        newFaceView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.insertSubview(newFaceView, at: 0)

        // 1. instruct face view to load its content
        newFaceView.load { (error) in

            printBV(info: "Face view load completion called.")

            // ensure no error
            guard error == nil else {
                // face view encountered an error
                self.state = .error
                return
            }

            // show face
            self.state = .completed

        }

    }

}
