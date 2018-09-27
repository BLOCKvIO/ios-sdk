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

// MARK: - Protocols

/// The protocol loading views must conform to in order to be displayed by `VatomView`.
public protocol VatomViewLoader where Self: UIView {
    /// Informs the implementer that loading should start.
    func startAnimating()
    /// Informs the implementor that loading should stop.
    func stopAnimating()
}

/// The protocol error views must conform to in order to be displayed by `VatomView`.
public protocol VatomViewError where Self: UIView {
    /// Vatom for which the error was generated.
    var vatom: VatomModel? { get set }
}

/// Types that manage a `VatomView` should conform to this delegate to know when the face has completed loading.
protocol VatomViewLifecycleDelegate: class {
    /// Called when the vatom view's selected face view has loaded successful or with an error.
    func faceViewDidCompleteLoad(error: Error?)
}

/*
 Design Goals:
 1. Vatom View will ask for the best face (default routine for each view context).
 2. Vatom View must use the global Face Registry (unless explicitly set).
 3. Vatom View must be reuseable in a list, .e.g. UICollectionView.
 -  When VatomView is pulled from a reuse pool, it's selected face view is most likely going to change. Viewer should
 prepareForReuse by calling `unLoad`.
 4. Viewers must be able to use embedded FSPs.
 5. Viewers must be able supply a custom FSP (defaults to the icon).
 */

/// Visualizes a vAtom by attempting to display one of the vAtom's face views.
///
/// A `VatomView` is the main render of a vAtom. That is, it contains logic to both select the best face view and to
/// coordinate the displaying and updating of the face view.
///
/// The face view displayed is dependent on the provided face selection procedure (FSP).
///
/// - note:
/// Loading and error views may be customized for all `VatomView` or per instance.
public class VatomView: UIView {

    // MARK: - Enums

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
                self.loaderView.isHidden = false
                self.loaderView.startAnimating()
                self.errorView.isHidden = true
            case .error:
                self.loaderView.isHidden = true
                self.loaderView.stopAnimating()
                self.errorView.isHidden = false
                self.errorView.vatom = self.vatom
            case .completed:
                self.selectedFaceView?.alpha = 1
                self.loaderView.isHidden = true
                self.loaderView.stopAnimating()
                self.errorView.isHidden = true
            }
        }
    }

    // MARK: - Properties

    /// The vatom to visualize.
    ///
    /// Setting the vatom will trigger the Vatom View Lifecylce (VVLC).
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
    public private(set) var roster: Roster

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
    /// To customise the loader view per instance of `VatomView` see `loaderView`.
    public static var defaultLoaderView: VVLoaderView.Type = DefaultLoaderView.self

    /// Class-level error view used as the *default* error view.
    ///
    /// This error view is shown in two cases. 1) The FSP fails to select a face view. 2) The face view fails to load
    /// and calls its completion handler with an error (in which case the face view is removed from the view hierarchy
    /// and replaced with this error view).
    ///
    /// - note:
    /// To customise the error view per instance of `VatomView` see `errorView`.
    public static var defaultErrorView: VVErrorView.Type = DefaultErrorView.self

    /// Instance level loader view. Use this to customize this view's loader view.
    public var loaderView: VVLoaderView {
        didSet {
            oldValue.removeFromSuperview()
            self.addSubview(loaderView)
            loaderView.frame = self.bounds
            loaderView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        }
    }

    /// Instance level error view. Use this to customize this view's error view.
    public var errorView: VVErrorView {
        didSet {
            oldValue.removeFromSuperview()
            self.addSubview(errorView)
            errorView.frame = self.bounds
            errorView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        }
    }

    // MARK: - Initializer

    /// Initialize without parameters.
    ///
    /// The Vatom View Lifecycle (VVLC) will only be run after calling `upadate(usingVatom:procedure:)`.
    public init() {
        self.procedure = EmbeddedProcedure.icon.procedure
        self.roster = FaceViewRoster.shared.roster
        self.loaderView = VatomView.defaultLoaderView.init()
        self.errorView = VatomView.defaultErrorView.init()
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    }

    /// Intializes using a vatom and optional procedure.
    ///
    /// The Vatom View Lifecycle (VVLC) automatically run.
    ///
    /// - Parameters:
    ///   - vatom: The vAtom to visualize.
    ///   - procedure: The Face Selection Procedure (FSP) that determines which face view to display.
    ///     Defaults to `.icon`.
    public init(vatom: VatomModel,
                procedure: @escaping FaceSelectionProcedure = EmbeddedProcedure.icon.procedure) {

        self.procedure = procedure
        self.roster = FaceViewRoster.shared.roster
        self.loaderView = VatomView.defaultLoaderView.init()
        self.errorView = VatomView.defaultErrorView.init()
        self.vatom = vatom
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        commonSetup()

        // don't wait for the dispatched block
        DispatchQueue.main.async {
            self.runVVLC()
        }

    }

    /// Intializes using a vatom and a procedure. Optional loading and error views must be supplied.
    ///
    /// The Vatom View Lifecycle (VVLC) automatically run.
    ///
    /// - Parameters:
    ///   - vatom: The vAtom to visualize.
    ///   - procedure: The Face Selection Procedure (FSP) that determines which face view to display.
    ///     Defaults to `.icon`.
    ///   - loadingView: Custom loading view to show before the face view concludes loading. Defaults to the standard
    ///     loading view.
    ///   - errorView: Custom error view to show in the event a face view is not selected or resolves an error.
    ///     Defaults to the standard error view.
    ///   - roster:
    public init(vatom: VatomModel,
                procedure: @escaping FaceSelectionProcedure = EmbeddedProcedure.icon.procedure,
                loadingView: VVLoaderView = VatomView.defaultLoaderView.init(),
                errorView: VVErrorView = VatomView.defaultErrorView.init(),
                roster: Roster = FaceViewRoster.shared.roster) {

        self.procedure = procedure
        self.loaderView = loadingView
        self.errorView = errorView
        self.roster = roster
        self.vatom = vatom
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        commonSetup()

        // don't wait for the dispatched block
        DispatchQueue.main.async {
            self.runVVLC()
        }

    }

    /// Initialize using aDecoder.
    ///
    /// The Vatom View Lifecycle (VVLC) will only be run after calling `upadate(usingVatom:procedure:)`.
    ///
    /// This initializer does not automatically run the VVLC. The caller must call `update(usingVatom:procedure:)`
    /// to begin the VVLC. Custom loaders and errors must be set prior to calling `update(usingVatom:procedure:)`.
    required public init?(coder aDecoder: NSCoder) {

        self.procedure = EmbeddedProcedure.icon.procedure
        self.roster = FaceViewRoster.shared.roster
        self.loaderView = VatomView.defaultLoaderView.init()
        self.errorView = VatomView.defaultErrorView.init()
        super.init(coder: aDecoder)

        commonSetup()
    }

    /// Common setup tasks
    private func commonSetup() {
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        self.addSubview(loaderView)
        self.addSubview(errorView)

        // add error and loading views
        loaderView.frame = self.bounds
        loaderView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        errorView.frame = self.bounds
        errorView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        self.state = .loading
    }

    // MARK: - State Management

    /// Updates the vAtom and optionally the procedure.
    ///
    /// Both vatom and procedure may be updated over the lifespan of the `VatomView`. If either are updated the VVLC
    /// will run. This and may (or may not) result in the selected face model changing.
    ///
    /// - If the selected face model remains the same, then updates will be passed down to the currently selected face
    /// view.
    /// - If the selected face model changes, then the current face view will be torndown an the newly selected face
    /// view added to the view hierarchy.
    ///
    /// - Parameters:
    ///   - newVatom: The vAtom to be visualized.
    ///   - procedure: The Face Selection Procedure (FSP) that determines which face view to display.
    public func update(usingVatom newVatom: VatomModel,
                       procedure: FaceSelectionProcedure? = nil) {

        // check for a vatom change, if so, enter loading sate
        if self.vatom?.id != newVatom.id {
            self.state = .loading
        }

        // assign if not nil
        procedure.flatMap { self.procedure = $0 }

        let oldVatom = self.vatom
        self.vatom = newVatom
        runVVLC(oldVatom: oldVatom)

    }

    /// Calling `unload` will inform the selected face view to unload its contents.
    ///
    /// 'Unload' within the context of a face view means: Cancelling resource downloading, `nil`-ing out image data.
    ///
    /// Call this method when `VatomView`:
    /// - goes off screen.
    /// - should `prepareForReuse` (if within a reuse pool).
    public func unLoad() {
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
    ///
    /// - Parameter oldVatom: The previous vAtom being visualized by this VatomView.
    internal func runVVLC(oldVatom: VatomModel? = nil) {

        guard let vatom = vatom else {
            assertionFailure("Developer error: vatom must not be nil.")
            return
        }

        //TODO: Offload FSP to a background queue.

        // 1. select the best face model
        guard let selectedFaceModel = procedure(vatom, Set(roster.keys)) else {

            /*
             Error - Case 1 - Show the error view if the FSP fails to select a face view.
             */

            //printBV(error: "Face Selection Procedure (FSP) returned without selecting a face model.")
            self.state = .error
            return
        }

        //printBV(info: "Face Selection Procedure (FSP) selected face model: \(selectedFaceModel)")

        /*
         Here we check:
         
         A. If selected face model is still equal to the current. This is necessary since the face may
         change as a result of the publisher modifying the face (typically via a delete/add operation).
         
         B. If the new vatom and the previous vatom share a template variation. This is needed since resources are
         defined at the template variation level.
         */

        // 2. check if the face model has not changed
        if (vatom.props.templateVariationID == oldVatom?.props.templateVariationID) &&
            (selectedFaceModel == self.selectedFaceModel) {

            //printBV(info: "Face model unchanged - Updating face view.")

            /*
             Although the selected face model has not changed, other items in the vatom may have, these updates
             must be passed to the face view to give it a change to update its state. The VVLC should not be re-run
             (since the selected face view does not need replacing).
             */

            self.state = .completed
            // update currently selected face view (without replacement)
            self.selectedFaceView?.vatomChanged(vatom)

        } else {

            //printBV(info: "Face model changed - Replacing face view.")

            // replace currently selected face model
            self.selectedFaceModel = selectedFaceModel

            // 3. find face view type
            guard let faceViewType = roster[selectedFaceModel.properties.displayURL] else {
                // viewer developer MUST have registered the face view with the face registry
                assertionFailure(
                    """
                    Developer error: Face selection procedure (FSP) selected a face without the face view being
                    installed. Your FSP MUST check if the face view has been registered with the FaceRegistry.
                    """)
                return
            }

            //printBV(info: "Face view for face model: \(faceViewType)")

            //let selectedFaceView: FaceView = ImageFaceView(vatom: vatom, faceModel: selectedFace)
            let selectedFaceView: FaceView = faceViewType.init(vatom: vatom,
                                                               faceModel: selectedFaceModel)

            // replace currently selected face view with newly selected
            self.replaceFaceView(with: selectedFaceView)

        }

    }

    /// Replaces the current face view (if any) with the specified face view and starts the FVLC.
    private func replaceFaceView(with newFaceView: (FaceView)) {

        // update current state
        self.state = .loading

        // request the face view unload it's contents
        self.selectedFaceView?.unload()
        self.selectedFaceView?.removeFromSuperview()
        self.selectedFaceView = nil
        self.selectedFaceView = newFaceView

        // insert face view into the view hierarcy
        newFaceView.frame = self.bounds
        newFaceView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.insertSubview(newFaceView, at: 0)

        // 1. instruct face view to load its content
        newFaceView.load { [weak self] (error) in

            ///printBV(info: "Face view load completion called.")

            // Error - Case 2 -  Display error view if the face view encounters an error during its load operation.

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
