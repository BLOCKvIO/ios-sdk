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

/// Native progress image face view
///
/// Assumption:
/// Both the empty and full images have the same size.
class ProgressImageFaceView: FaceView {

    class var displayURL: String { return "native://progress-image-overlay" }

    // MARK: - Properties

    public private(set) var isLoaded: Bool = false

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0%"
        label.textAlignment = .right
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        return label
    }()

    private lazy var emptyImageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        imageView.frame = self.bounds
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var fullImageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        imageView.frame = self.bounds
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private let emptyImageContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private let fullImageContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    // MARK: - Dynamic Vatom Private Properties

    private var progress: CGFloat {
        return  CGFloat(min(1, max(0, vatom.props.cloningScore)))
    }

    // MARK: - Config

    /// Face model face configuration specification.
    ///
    /// Face config is immutable.
    private struct Config {

        // defaults
        var emptyImageName: String = "BaseImage"
        var fullImageName: String = "ActivatedImage"
        var direction: String = "up"
        var paddingEnd: Double = 0
        var paddingStart: Double = 0
        var showPercentage: Bool = true

        /// Initialize using default values.
        init() {}

        /// Initialize using face configuration.
        init(_ faceConfig: JSON) {

            // assign iff not nil
            self.emptyImageName ?= faceConfig["empty_image"]?.stringValue
            self.fullImageName  ?= faceConfig["full_image"]?.stringValue
            self.direction      ?= faceConfig["direction"]?.stringValue
            self.showPercentage ?= faceConfig["show_percentage"]?.boolValue

            /*
             Legacy Note:
             The specification calls for `padding_end` and `padding_start` to be of type Float. However some older
             vAtoms have these values as type String. This is temporary – String types will be depreciated.
             */
            if let paddingEnd = faceConfig["padding_end"]?.floatValue {
                self.paddingEnd ?= Double(paddingEnd)
            } else if let endString = faceConfig["padding_end"]?.stringValue, // legacy!
                let end = Double(endString) {
                self.paddingEnd = end
            }

            if let paddingStart = faceConfig["padding_start"]?.floatValue {
                self.paddingStart = Double(paddingStart)
            } else if let startString = faceConfig["padding_start"]?.stringValue, // legacy!
                let start = Double(startString) {
                self.paddingStart = start
            }
        }

    }

    /// Face configuration (immutable).
    ///
    /// On the server, Faces and Actions are mutable (irrespective of the published state of the template). Face Views
    /// however treat face config as immutable. If the face config changes (typically by the publisher deleting and
    /// re-adding the face) the Face View should be torn down and recreated.
    ///
    /// Dynamically responding to face and action changes is not a function of Face Views. For this reason, the config
    /// struct immutalbe and is ONLY populated on init.
    private let config: Config

    // MARK: - Initialization

    required init(vatom: VatomModel, faceModel: FaceModel) {

        // init face config (or legacy private section) fallback on default values

        if let config = faceModel.properties.config {
            self.config = Config(config) // face config
        } else if let config = vatom.private {
            self.config = Config(config) // private section
        } else {
            self.config = Config() // default values
        }

        super.init(vatom: vatom, faceModel: faceModel)

        // setup
        emptyImageContainer.frame = self.bounds
        fullImageContainer.frame = self.bounds
        self.addSubview(emptyImageContainer)
        self.addSubview(fullImageContainer)
        emptyImageContainer.addSubview(emptyImageView)
        fullImageContainer.addSubview(fullImageView)

        // progress label
        self.addSubview(progressLabel)
        progressLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        progressLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10).isActive = true
        progressLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true

        self.backgroundColor = UIColor.yellow.withAlphaComponent(0.3)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

    // MARK: - FaceView Lifecycle

    func load(completion: ((Error?) -> Void)?) {

        self.updateResources { (error) in
            self.setNeedsLayout()
            self.updateUI()
            completion?(error)
        }

    }

    func vatomChanged(_ vatom: VatomModel) {

        // update vatom
        self.vatom = vatom
        updateUI()
    }

    func unload() { }

    // MARK: - View Lifecycle

    // Updates the UI using local data.
    private func updateUI() {
        self.progressLabel.isHidden = !self.config.showPercentage
        self.progressLabel.text = "\(Int(progress * 100))%"

        // request layout
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    /// Updates the empty and full images and their containers to show the "progress" of the vAtom.
    override func layoutSubviews() {
        super.layoutSubviews()

        // image size
        guard let image = fullImageView.image else { return }
        // convert to points
        let imagePoints = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        // normalize padding i.t.o the view's point size
        var paddingStartNorm: CGFloat = 0
        var paddingEndNorm: CGFloat = 0

        switch self.config.direction.lowercased() {
        case "left", "right":
            paddingStartNorm = CGFloat(self.config.paddingStart) / imagePoints.width * self.bounds.size.width
            paddingEndNorm = CGFloat(self.config.paddingEnd) / imagePoints.width * self.bounds.size.width
        default: // "up", "down"
            paddingStartNorm = CGFloat(self.config.paddingStart) / imagePoints.height * self.bounds.size.height
            paddingEndNorm = CGFloat(self.config.paddingEnd) / imagePoints.height * self.bounds.size.height
        }

        // check direction
        if self.config.direction == "down" {

            // top to bottom
            let offset = floor(progress * (self.bounds.size.height - paddingEndNorm - paddingStartNorm)
                - paddingStartNorm)
            emptyImageContainer.frame =
                CGRect(x: 0, y: offset, width: self.bounds.size.width, height: self.bounds.size.height - offset)
            emptyImageView.frame =
                CGRect(x: 0, y: -offset, width: self.bounds.size.width, height: self.bounds.size.height)
            fullImageContainer.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: offset)
            fullImageView.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)

        } else if self.config.direction == "up" {

            // bottom to top
            let offsetRange = (self.bounds.size.height - paddingEndNorm - paddingStartNorm)
            let offset = floor((1-progress) * offsetRange + paddingEndNorm)
            emptyImageContainer.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: offset)
            emptyImageView.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
            fullImageContainer.frame =
                CGRect(x: 0, y: offset, width: self.bounds.size.width, height: self.bounds.size.height - offset)
            fullImageView.frame =
                CGRect(x: 0, y: -offset, width: self.bounds.size.width, height: self.bounds.size.height)

        } else if self.config.direction == "left" {

            // right to left
            let offsetRange = (self.bounds.size.width - paddingEndNorm - paddingStartNorm)
            let offset = floor((1-progress) * offsetRange + paddingEndNorm)
            emptyImageContainer.frame =
                CGRect(x: 0, y: 0, width: offset, height: self.bounds.size.height)
            emptyImageView.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
            fullImageContainer.frame =
                CGRect(x: offset, y: 0, width: self.bounds.size.width - offset, height: self.bounds.size.height)
            fullImageView.frame =
                CGRect(x: -offset, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)

        } else {

            // left to right
            let offset = floor(progress * (self.bounds.size.width - paddingEndNorm - paddingStartNorm)
                - paddingStartNorm)
            emptyImageContainer.frame =
                CGRect(x: offset, y: 0, width: self.bounds.size.width - offset, height: self.bounds.size.height)
            emptyImageView.frame =
                CGRect(x: -offset, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
            fullImageContainer.frame =
                CGRect(x: 0, y: 0, width: offset, height: self.bounds.size.height)
            fullImageView.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)

        }

    }

    // MARK: - Resource Management

    // group async events
    private let dispatchGroup = DispatchGroup()

    /// Fetches required resources and populates the relevant `ImageView`s. The completion handler is called once all
    /// images are downloaded (or an error is encountered).
    private func updateResources(completion: ((Error?) -> Void)?) {

        // ensure required resources are present
        guard
            let emptyImageResource = vatom.props.resources.first(where: { $0.name == self.config.emptyImageName }),
            let fullImageResource = vatom.props.resources.first(where: { $0.name == self.config.fullImageName })
            else {
                printBV(error: "\(#file) - failed to extract resources.")
                return
        }

        // ensure encoding passes
        guard
            let emptyURL = try? BLOCKv.encodeURL(emptyImageResource.url),
            let fullURL = try? BLOCKv.encodeURL(fullImageResource.url)
            else {
                printBV(error: "\(#file) - failed to encode resources.")
                return
        }

        dispatchGroup.enter()
        dispatchGroup.enter()

        // load image (automatically handles reuse)
        Nuke.loadImage(with: emptyURL, into: self.emptyImageView) { (_, _) in
            self.dispatchGroup.leave()
        }

        // load image (automatically handles reuse)
        Nuke.loadImage(with: fullURL, into: self.fullImageView) { (_, _) in
            self.dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.isLoaded = true
            completion?(nil)
        }

    }

}
