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

/// Default error view.
///
/// Shows:
/// 1. vAtoms activated image.
/// 2. Warning trigangle (that is tappable).
internal final class DefaultErrorView: BoundedView & VatomViewError {

    // MARK: - Debug

    /// A Boolean value controlling whether the error view is in debug mode.
    ///
    /// Debug mode redueces the image's alpha and adds a info button.
    public var isDebugEnabled = false {
        didSet {
            if isDebugEnabled {
                self.activatedImageView.alpha = 0.3
                self.infoButton.isEnabled = true
            }
        }
    }

    // MARK: - Properties

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let infoButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.infoLight)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.orange
        return button
    }()

    private let activatedImageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var vatom: VatomModel? {
        didSet {
            // raise flag that layout is needed on the bounds are known
            self.requiresBoundsBasedSetup = true
        }
    }

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(activatedImageView)
        self.addSubview(activityIndicator)
        self.addSubview(infoButton)

        activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

        infoButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -12).isActive = true
        infoButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12).isActive = true

        activatedImageView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        activatedImageView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        activatedImageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        activatedImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        ImagePipeline.Configuration.isAnimatedImageDataEnabled = true

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupWithBounds() {
        super.setupWithBounds()
        // only at this point is the bounds known which can be used to compute the target size
        loadResources()
    }

    // MARK: - Logic

    /// Loads the required resources.
    ///
    /// The error view uses the activated image as a placeholder.
    private func loadResources() {

        activityIndicator.startAnimating()

        // extract error
        guard let vatom = vatom else {
            assertionFailure("Vatom must not be nil.")
            return
        }

        // extract resource model
        guard let resourceModel = vatom.props.resources.first(where: { $0.name == "ActivatedImage" }) else {
            return
        }

        // encode url
        guard let encodeURL = try? BLOCKv.encodeURL(resourceModel.url) else {
            return
        }
        
        let targetSize = self.activatedImageView.pixelSize
        // create request
        var request = ImageRequest(url: encodeURL,
                                   targetSize: targetSize,
                                   contentMode: .aspectFill)
        
        // set cache key
        request.cacheKey = request.generateCacheKey(url: resourceModel.url, targetSize: targetSize)
        
        // load image
        Nuke.loadImage(with: request, into: activatedImageView) { [weak self] (_, _) in
            self?.activityIndicator.stopAnimating()
        }

    }

}
