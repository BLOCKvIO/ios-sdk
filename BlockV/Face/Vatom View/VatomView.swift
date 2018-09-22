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
 
 Issues
 
 If Face Views perform their own downloading of resources it leads to an interesting issue around async + reuse.
 
 - Consider a long running download.
 1. Cell comes on screen, Vatom View runs it's routine, selects a face model
    init's the face view and asks it to load. May show error, or loader.
 - If the cell is on screen still, and the download completes it will set the imageView's image property (because it
   has a reference to it.
 - If the download is ongoing and the cell has gone off screen it may have been placed in reuse pool.
 
 Now, it all depends on the implementation as to how this is handled.
 - If the cell a reused by not nil-ing vatom view, then the
 
 ###
 
 When VatomView come out a the reuse pool, it's selected face view is most likely going to change. This means there
 will be a flicker on the screen while the VVR runs followed by the face view loading it's content.
 
 Is there any way to get around this? Maybe better caching?
 
 -----------------------
 
 Use Cases
 
 1. Stand alone
    - must handle everything
 2. Reusable cell in a list
    -
 
 Using VatomView within a cell that is to be reused.
 
 This is a common use case for devs that want to integrate vatoms into a table list interface in their own apps.
 
 Options:
 1. nil out vAtom view (how will this work in storyboards)
 2. add a `prepareForReuse()` method to VatomView, vatom view will then propagate the change to it's selected face view.
 
 */

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
 Main renderer.
 
 
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
                self.loadingView.isHidden = false
                self.loadingView.startAnimating()
                self.errorView.isHidden = true
            case .error:
                self.loadingView.isHidden = true
                self.loadingView.stopAnimating()
                self.errorView.isHidden = false
                self.errorView.vatom = self.vatom
            case .completed:
                self.selectedFaceView?.alpha = 1
                self.loadingView.isHidden = true
                self.loadingView.stopAnimating()
                self.errorView.isHidden = true
            }
        }
    }

    // MARK: - Properties

    /// The vatom to visualize.
    public private(set) var vatom: VatomModel?

    /// The face selection procedure used to select a face view.
    ///
    /// Viewers may wish to update the procedure in reponse to certian events. For example, the viewer may change the
    /// procedure from 'icon' to 'engaged' while the VatomView is on screen.
    public private(set) var procedure: FaceSelectionProcedure

    /// List of all the installed face views.
    ///
    /// The roster is a consolidated list of the face views registered by both the SDK and Viewer.
    /// This list represents the face views that are *capable* of being rendered.
    public private(set) var roster: FaceViewRoster

    /// Face model selected by the specifed face selection procedure (FSP).
    public private(set) var selectedFaceModel: FaceModel?

    /// Selected face view (function of the selected face model).
    public private(set) var selectedFaceView: FaceView?

    // MARK: Customization

    /// Loading views must derive from `UIView` and conform to `VatomViewLoader`.
    public typealias VVLoaderView = (UIView & VatomViewLoader)
    /// Error views must derive from `UIView` and conform to `VatomViewError`.
    public typealias VVErrorView = (UIView & VatomViewError)

    /// Class-level loading view used as the *default* loading view.
    ///
    /// This loading view is shown when the vAtom begins loading and is replaced by the face view once the face view
    /// calls its `load` completion handler.
    ///
    /// - note:
    /// To customise the loading view per instance of `VatomView` see `loadingView`.
    public static var defaultLoadingView: VVLoaderView.Type = DefaultLoadingView.self

    /// Class-level error view used as the *default* error view.
    ///
    /// This error view is shown in two cases. 1) The FSP fails to select a face view. 2) The face view fails to load
    /// and calls its completion handler with an error (in which case the face view is removed from the view hierarchy
    /// and replaced with this error view).
    ///
    /// - note:
    /// To customise the error view per instance of `VatomView` see `errorView`.
    public static var defaultErrorView: VVErrorView.Type = DefaultErrorView.self

    /// Instance level loading view. Use this to customize the default loading view.
    public var loadingView: VVLoaderView
    /// Instance level error view. Use this to customize the default error view.
    public var errorView: VVErrorView

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
        self.loadingView = VatomView.defaultLoadingView.init()
        self.errorView = VatomView.defaultErrorView.init()

        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        commonInit()
        //runVVLC()
    }

    public init(vatom: VatomModel,
                procedure: @escaping FaceSelectionProcedure = EmbeddedProcedure.icon.procedure,
                loadingView: VVLoaderView = VatomView.defaultLoadingView.init(),
                errorView: VVErrorView = VatomView.defaultErrorView.init(),
                roster: FaceViewRoster = FaceViewRegistry.shared.roster) {

        self.vatom = vatom
        self.procedure = procedure
        self.loadingView = loadingView
        self.errorView = errorView
        self.roster = roster

        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        commonInit()
        //runVVLC()
    }

    /// Initialize using aDecoder.
    ///
    /// This initializer does not automatically run the Vatom View Life Cycle (VVLC).
    /// You must call `update(usingVatom:procedure:)` to begin the Vatom View Life Cycle.
    /// To customize this instance's loading and error view
    required public init?(coder aDecoder: NSCoder) {

        self.procedure = EmbeddedProcedure.icon.procedure
        self.roster = FaceViewRegistry.shared.roster
        self.loadingView = VatomView.defaultLoadingView.init()
        self.errorView = VatomView.defaultErrorView.init()

        super.init(coder: aDecoder)

        commonInit()
    }

    /// Common initializer
    private func commonInit() {
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        self.addSubview(loadingView)
        self.addSubview(errorView)

        loadingView.frame = self.bounds
        loadingView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        errorView.frame = self.bounds
        errorView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        self.state = .loading
    }

    // MARK: - State Management

    /*
     Both vatom and the procedure may be updated over the life of the vatom view.
     This means if either is updated, the VVLC should run.
     
     Either update may (or may not) result in the selectedFaceModel changing. If it does a full FaceView replacement is
     needed.
     
     If the vatom is updated, and the selectedFaceModel remains the same, then updates may (or may not) need to be
     passed down to the currently selected face view.
     
     */

    /// Updates the vAtom view and triggers a run of the VVLC.
    ///
    /// - Parameters:
    ///   - newVatom: The new vAtom to be visualized.
    ///   - procedure: The Face Selection Procedure (FSP) to use.
    public func update(usingVatom newVatom: VatomModel,
                       procedure: FaceSelectionProcedure? = nil) {

        // check for a vatom change, if so, enter loading sate
        if self.vatom?.id != newVatom.id {
            self.state = .loading
        }

        self.vatom = newVatom
        procedure.flatMap { self.procedure = $0 } // assign if not nil

        runVVLC()

    }

    /// Host may want to inform the face view to cancel loading. For example, cancel loading large resources etc.
    ///
    /// You should call this when:
    /// - VatomView goes off screen.
    /// - VatomView is in a reuse pool and the cell receives the `prepareForReuse` method call.
    public func unLoad() {
        // pass the unload message along to selected face view
        self.selectedFaceView?.unload()
    }

    /// Vatom View Life Cycle error
    public enum VVLCError: Error, CustomStringConvertible {

        case selectionFailed
        case unregisteredFaceViewSelected(_ displayURL: String)

        public var description: String {
            switch self {
            case .selectionFailed:
                return "Face Selection Procedure (FSP) did not to select a face view."
            case .unregisteredFaceViewSelected(let url):
                return """
                Face selection procedure (FSP) selected a face view '\(url)' without the face view being registered.
                """
            }
        }

    }

    // MARK: - Vatom View Life Cycle

    /// Exectues the Vatom View Lifecycle (VVLC) on the current vAtom.
    ///
    /// 1. Run face selection procedure
    /// > Compare the selected face to the current face
    /// 2. Create face view
    /// 3. Inform the face view to load it's content
    /// 4. Display the face view
    public func runVVLC() {

        //FIXME: Part of this could run on a background thread, e.g fsp

        precondition(vatom != nil, "vatom must not be nil.")

        guard let vatom = vatom else { return } //FIXME: Show error?

        // 1. select the best face model
        guard let selectedFaceModel = procedure(vatom, Set(roster.keys)) else {

            /*
             Error - Case 1 - Show the error view if the FSP fails to select a face view.
             */

            printBV(error: "Face Selection Procedure (FSP) returned without selecting a face model.")
            self.state = .error
            return
        }

        printBV(info: "Face Selection Procedure (FSP) selected face model: \(selectedFaceModel)")

        /*
         check if selected face model has changed (rare cases where the face config was updated while the vatom is in
         the unpublished state.
         */

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

            // replace currently selected face view with newly selected
            self.replaceFaceView(with: selectedFaceView)

        }

    }

    /// Replaces the current face view (if any) with the specified face view and starts the FVLC.
    ///
    /// Call this function only if you want a full replace of the current face view.
    ///
    /// Triggers the Face View Life Cycle (VVLC)
    private func replaceFaceView(with newFaceView: (FaceView)) {

        /*
         Options: This function could take in a FaceView instance, or take in a FaceView.Type and create the instance
         itself (using the generator)?
         */

        // Update current state
        self.state = .loading

        // remove before setting to nil
        self.selectedFaceView?.removeFromSuperview()
        self.selectedFaceView = nil

        // update currently selected face view
        self.selectedFaceView = newFaceView

        // insert face view into the view hierarcy
        newFaceView.frame = self.bounds
        newFaceView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.insertSubview(newFaceView, at: 0)

        // 1. instruct face view to load its content
        newFaceView.load { [weak self] (error) in

            printBV(info: "Face view load completion called.")

            /*
             Error - Case 2 -  Display error view if the face view encounters an error during its load operation.
             */

            // ensure no error
            guard error == nil else {
                // face view encountered an error
                self?.selectedFaceView?.removeFromSuperview()
                self?.state = .error
                return
            }

            // show face
            self?.state = .completed

        }

    }

}
