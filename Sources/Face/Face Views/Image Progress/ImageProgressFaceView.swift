//
//  BLOCKv AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BLOCKv SDK License (the "License"); you may not use this file or
//  the BLOCKv SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BLOCKv SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import os
import UIKit
import Nuke
import GenericJSON

/// Native progress image face view
///
/// Assumption:
/// Both the empty and full images have the same size.
class ImageProgressFaceView: FaceView {

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

    private lazy var emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.bounds
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var fullImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var clippingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()

    // MARK: - Dynamic Vatom Private Properties

    private var progress: CGFloat {
        return CGFloat(min(1, max(0, vatom.props.cloningScore)))
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

            if let paddingEnd = faceConfig["padding_end"]?.doubleValue {
                self.paddingEnd ?= Double(paddingEnd)
            }
            if let paddingStart = faceConfig["padding_start"]?.doubleValue {
                self.paddingStart = Double(paddingStart)
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
    
    private var directionalConstraint: NSLayoutConstraint!

    // MARK: - Initialization

    required init(vatom: VatomModel, faceModel: FaceModel) throws {

        // init face config (or legacy private section) fallback on default values

        if let config = faceModel.properties.config, config != .null {
            self.config = Config(config) // face config
        } else if let config = vatom.private {
            self.config = Config(config) // private section
        } else {
            self.config = Config() // default values
        }

        try super.init(vatom: vatom, faceModel: faceModel)

        self.addSubview(emptyImageView)
        self.addSubview(clippingView)
        clippingView.addSubview(fullImageView)
        
        // progress label
        self.addSubview(progressLabel)
        progressLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        progressLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10).isActive = true
        progressLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        fullImageView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        fullImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        fullImageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        fullImageView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
                
        switch self.config.direction {
            
        case "left":
            clippingView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            clippingView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
            clippingView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            directionalConstraint =  NSLayoutConstraint(item: clippingView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.5, constant: 0)
            directionalConstraint.isActive = true
        case "right":
            clippingView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            clippingView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            clippingView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            directionalConstraint =  NSLayoutConstraint(item: clippingView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.5, constant: 0)
            directionalConstraint.isActive = true
        case "down":
            clippingView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            clippingView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            clippingView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
            directionalConstraint =  NSLayoutConstraint(item: clippingView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 0.5, constant: 0)
            directionalConstraint.isActive = true
        default:
            clippingView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
            clippingView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
            clippingView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            directionalConstraint =  NSLayoutConstraint(item: clippingView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 0.5, constant: 0)
            directionalConstraint.isActive = true
        }
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

    // MARK: - FaceView Lifecycle

    /// Begins loading the face view's content.
    func load(completion: ((Error?) -> Void)?) {

        // reset content
        self.reset()
        /// load required resources
        self.loadResources { [weak self] error in

            guard let self = self else { return }
            // update state and inform delegate of load completion
            if let error = error {
                self.setNeedsLayout()
                self.updateUI()
                self.isLoaded = false
                completion?(error)
            } else {
                self.setNeedsLayout()
                self.updateUI()
                self.isLoaded = true
                completion?(nil)
            }

        }

    }

    /// Updates the backing Vatom and loads the new state.
    func vatomChanged(_ vatom: VatomModel) {

        self.vatom = vatom
        // update ui
        self.setNeedsLayout()
        self.updateUI()

    }

    /// Resets the contents of the face view.
    private func reset() {
        emptyImageView.image = nil
        fullImageView.image = nil
    }

    func unload() {
        reset()
        //TODO: Cancel all downloads
    }

    // MARK: - View Lifecycle

    /// Updates the UI using local data.
    private func updateUI() {
        self.progressLabel.isHidden = !self.config.showPercentage
        self.progressLabel.text = "\(Int(progress * 100))%"

        // request layout
        self.setNeedsLayout()
        self.layoutIfNeeded()
        self.updateMask()
        self.layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        print(#function)

        // show/hide progress label based on current size
        if self.bounds.size.width < 100 {
            progressLabel.isHidden = true
        } else {
            progressLabel.isHidden = false
        }

    }
    
    private func updateMask() {

        if self.bounds == CGRect.zero {
            print("bounds are zero")
            return
        }

        // image size
        guard let image = fullImageView.image else { return }

        // - Pixels
        // size of image in pixels
        let imagePixelSize = CGSize(width: (image.size.width * image.scale), height: (image.size.height * image.scale))

        // rect of the image inside the image view
        let contentClippingRect = self.emptyImageView.contentClippingRect

        let paddingStart = contentClippingRect.height * CGFloat(self.config.paddingStart) / imagePixelSize.height
        let paddingEnd = contentClippingRect.width * CGFloat(self.config.paddingEnd) / imagePixelSize.width

        let innerY = contentClippingRect.height - paddingStart - paddingEnd
        let innerX = contentClippingRect.width - paddingStart - paddingEnd

        let innerProgressY = innerY * progress
        let innerProgressX = innerX * progress

        var percentage: CGFloat

        switch self.config.direction.lowercased() {

        case "left":
            let paddingStart = contentClippingRect.width * CGFloat(self.config.paddingStart) / imagePixelSize.width
            let paddingEnd = contentClippingRect.width * CGFloat(self.config.paddingEnd) / imagePixelSize.width

            let innerX = contentClippingRect.width - paddingStart - paddingEnd
            let innerProgressX = innerX * progress

            let directionOffset: CGFloat = paddingStart + innerProgressX
            let absoluteOffset = contentClippingRect.minX + directionOffset
            percentage = 1 - (absoluteOffset / self.bounds.width)

        case "right":
            let paddingStart = contentClippingRect.width * CGFloat(self.config.paddingStart) / imagePixelSize.width
            let paddingEnd = contentClippingRect.width * CGFloat(self.config.paddingEnd) / imagePixelSize.width

            let innerX = contentClippingRect.width - paddingStart - paddingEnd
            let innerProgressX = innerX * progress

            let directionOffset: CGFloat = paddingStart + innerProgressX
            let absoluteOffset = contentClippingRect.minX + directionOffset
            percentage = absoluteOffset / self.bounds.width

        case "down":
            let paddingStart = contentClippingRect.height * CGFloat(self.config.paddingStart) / imagePixelSize.height
            let paddingEnd = contentClippingRect.height * CGFloat(self.config.paddingEnd) / imagePixelSize.height

            let innerY = contentClippingRect.height - paddingStart - paddingEnd
            let innerProgressY = innerY * progress

            let directionOffset: CGFloat = paddingStart + innerProgressY
            let absoluteOffset = contentClippingRect.maxY - directionOffset
            percentage = absoluteOffset / self.bounds.height

        default: // "up"

            let paddingStart = contentClippingRect.height * CGFloat(self.config.paddingStart) / imagePixelSize.height
            let paddingEnd = contentClippingRect.height * CGFloat(self.config.paddingEnd) / imagePixelSize.height

            let innerY = contentClippingRect.height - paddingStart - paddingEnd
            let innerProgressY = innerY * progress

            let directionOffset: CGFloat = paddingStart + innerProgressY
            let absoluteOffset = contentClippingRect.maxY - directionOffset
            percentage = 1 - (absoluteOffset / self.bounds.height)
 
        }
        // update constraint
        self.directionalConstraint = self.directionalConstraint.setMultiplier(multiplier: percentage)

    }

    private var maskLayer = CAShapeLayer()

    // MARK: - Resource Management

    // group async events
    private let dispatchGroup = DispatchGroup()

    /// Fetches required resources and populates the relevant `ImageView`s. The completion handler is called once all
    /// images are downloaded (or an error is encountered).
    private func loadResources(completion: @escaping (Error?) -> Void) {

        // ensure required resources are present
        guard
            let emptyImageResource = vatom.props.resources.first(where: { $0.name == self.config.emptyImageName }),
            let fullImageResource = vatom.props.resources.first(where: { $0.name == self.config.fullImageName })
            else {
                completion(FaceError.missingVatomResource)
                return
        }

        // NB: Do not resize due to brittle pixel offsets in face config.
        let emptyRequest = BVImageRequest(url: emptyImageResource.url)
        let fullRequest = BVImageRequest(url: fullImageResource.url)

        dispatchGroup.enter()
        dispatchGroup.enter()
        // load images
        ImageDownloader.loadImage(with: emptyRequest, into: self.emptyImageView) { [weak self] result in
            self?.dispatchGroup.leave()
            do {
                try result.get()
            } catch {
                os_log("Failed to load: %@", log: .vatomView, type: .error, emptyImageResource.url.description)
            }
        }
        ImageDownloader.loadImage(with: fullRequest, into: self.fullImageView) { [weak self] result in
            self?.dispatchGroup.leave()
            do {
                try result.get()
            } catch {
                os_log("Failed to load: %@", log: .vatomView, type: .error, fullImageResource.url.description)
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.isLoaded = true
            completion(nil)
        }

    }

}

extension NSLayoutConstraint {
    /**
     Change multiplier constraint

     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
    */
    func setMultiplier(multiplier: CGFloat) -> NSLayoutConstraint {

        NSLayoutConstraint.deactivate([self])

        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)

        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier

        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}
