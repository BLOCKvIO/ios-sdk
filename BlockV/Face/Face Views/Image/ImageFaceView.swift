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

import UIKit
import FLAnimatedImage
import Nuke

/// Native Image face view
class ImageFaceView: FaceView {

    class var displayURL: String { return "native://image" }

    // MARK: - Properties

    lazy var animatedImageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.clipsToBounds = true
        return imageView
    }()

    public private(set) var isLoaded: Bool = false

    // MARK: - Config

    /// Face model face configuration specification.
    private struct Config {

        enum Scale: String {
            case fit, fill
        }

        // defaults
        var scale: Scale = .fit
        var imageName: String = "ActivatedImage"

        /// Initialize using face model.
        ///
        /// The config has a set of default values. If the face config section is present, those values are used in
        /// place of the default ones.
        ///
        /// ### Legacy Support
        /// The first resource name in the resources array (if present) is used in place of the activate image.
        init(_ faceModel: FaceModel) {

            // legacy: overwrite fallback if needed
            self.imageName ?= faceModel.properties.resources.first

            if let config = faceModel.properties.config {
                // assign iff not nil
                if let scaleString = config["scale"]?.stringValue {
                    self.scale ?= Config.Scale(rawValue: scaleString)
                }
                self.imageName ?= config["image"]?.stringValue
            }

        }
    }

    /// Face configuration.
    ///
    /// This property is *immutable* by design.
    ///
    /// The BLOCKv platform allows faces to change overtime (through a delete/recreate operation) - however this is
    /// rare and generally unadvised after a vAtom has been published. Viewers should treat the face config as
    /// immutable.
    ///
    /// It is the responsibility of VatomView to detect a change in the face config (and to recreate the face view if
    /// needed).
    private let config: Config

    // MARK: - Initialization

    required init(vatom: VatomModel, faceModel: FaceModel) {

        // init face config
        self.config = Config(faceModel)

        super.init(vatom: vatom, faceModel: faceModel)

        // add image view
        self.addSubview(animatedImageView)
        animatedImageView.frame = self.bounds

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

    // MARK: - View Lifecylce

    override func layoutSubviews() {
        super.layoutSubviews()

        updateContentMode()
    }

    /// FIXME: This method is only necessary if the scale config will change after init. In GV, the content mode of the
    /// image view changes based on bounds of the view - will this logic be needed?
    ///
    /// Update the content mode of the image view.
    ///
    /// Inspects the face config first and uses the scale if available. If no face config is found, a simple heuristic
    /// is used to choose the best content mode.
    private func updateContentMode() {

        // check face config
        switch config.scale {
        case .fill: animatedImageView.contentMode = .scaleAspectFill
        case .fit:  animatedImageView.contentMode = .scaleAspectFit
        }

    }

    // MARK: - Face View Lifecycle

    /// Begin loading the face view's content.
    func load(completion: ((Error?) -> Void)?) {
        updateResources(completion: completion)
    }

    /// Respond to updates or replacement of the current vAtom.
    func vatomChanged(_ vatom: VatomModel) {

        /*
         NOTE:
         - The ImageFaceView does not have any visually dynamic attributes.
         - The properties this face references on the vAtom are immutable after the vAtom has been emmitted.
         - Thus, no meaningful UI update can be made.
         */

        // replace current vatom
        self.vatom = vatom
        updateResources(completion: nil)

    }

    /// Unload the face view.
    ///
    /// Also called before reuse (when used inside a reuse pool).
    func unload() {
        self.animatedImageView.image = nil
        self.animatedImageView.animatedImage = nil
    }

    // MARK: - Resources

    private func updateResources(completion: ((Error?) -> Void)?) {

        // extract resource model
        guard let resourceModel = vatom.props.resources.first(where: { $0.name == config.imageName }) else {
            return
        }

        // encode url
        guard let encodeURL = try? BLOCKv.encodeURL(resourceModel.url) else {
            return
        }

        //FIXME: Where should this go?
        ImagePipeline.Configuration.isAnimatedImageDataEnabled = true

        //TODO: Should the size of the VatomView be factoring in and the image be resized?

        // load image (automatically handles reuse)
        Nuke.loadImage(with: encodeURL, into: self.animatedImageView) { (_, error) in
            self.isLoaded = true
            completion?(error)
        }

    }

}
