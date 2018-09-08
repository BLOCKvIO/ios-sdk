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
import FLAnimatedImage

/// FIXME: This operator has a drawback in that it always makes an assignment.
infix operator ?=
internal func ?=<T> (lhs: inout T, rhs: T?) {
    lhs = rhs ?? lhs
}

class ProgressImageFaceView: FaceView {

    // computed class var allows subclasses to override
    class var displayURL: String { return "native://progress-image-overlay" }

    // MARK: - Properties

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.frame = CGRect(x: 10, y: 0, width: self.bounds.size.width - 10, height: 20)
        label.autoresizingMask = [ .flexibleWidth ]
        label.text = "0%"
        label.textAlignment = .right
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 13)
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
        return  CGFloat(min(1, max(0, vatom.cloningScore)))
    }

    // MARK: - Config

    /// Face model face configuration specification.
    ///
    /// Face congig is immutable.
    private struct Config {

        // defaults
        var emptyImageName: String = "BaseImage"
        var fullImageName: String = "ActivatedImage"
        var direction: String = "up"
        var paddingEnd: Double = 0
        var paddingStart: Double = 0
        var showPercentage: Bool = false

        init() {}

        init(_ faceConfig: JSON) {
            // assign iff not nil
            self.emptyImageName ?= faceConfig["empty_image"]?.stringValue
            self.fullImageName ?= faceConfig["full_image"]?.stringValue
            self.direction ?= faceConfig["direction"]?.stringValue
            //FIXME: The spec must be changed to make padding values doubles
            self.paddingEnd ?= Double(faceConfig["padding_end"]?.stringValue ?? "0")
            self.paddingStart ?= Double(faceConfig["padding_start"]?.stringValue ?? "0")
            self.showPercentage ?= faceConfig["show_percentage"]?.boolValue
        }

    }

    /// Face configuration.
    ///
    /// The configuraton is immutable. If the face config is updated during a template's *unpublished* phase, vatom
    /// view should discard the face view and bring up a new one.
    private let config: Config

    // MARK: - Initialization

    required init(vatom: VatomModel, faceModel: FaceModel) {

        // init face config
        if let faceConfig = faceModel.properties.config {
            // use specific config
            self.config = Config(faceConfig)
        } else {
            // use default config
            self.config = Config()
        }

        super.init(vatom: vatom, faceModel: faceModel)

        // setup
        emptyImageContainer.frame = self.bounds
        fullImageContainer.frame = self.bounds
        self.addSubview(emptyImageContainer)
        self.addSubview(fullImageContainer)
        emptyImageContainer.addSubview(emptyImageView)
        fullImageContainer.addSubview(fullImageView)

        self.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

    // MARK: - FaceView Lifecycle

    func load(completion: @escaping (Error?) -> Void) {
        print(#function)

        //FIXME: Replace with resource end game
        self.doResourceStuff { (error) in
            self.setNeedsLayout()
            completion(error)
        }

    }

    func vatomUpdated(_ vatom: VatomModel) {
        print(#function)

        // update vatom
        self.vatom = vatom

        // request layout
        self.setNeedsLayout()
    }

    func unload() {
        print(#function)
    }

    func prepareForReuse() {
        print(#function)
    }

    // MARK: - View Lifecycle

    /// Set frame rectangles directly.
    override func layoutSubviews() {
        super.layoutSubviews()

        // image size
        let imageSize = fullImageView.image?.size ?? CGSize(width: 320, height: 320)

        // check direction
        if self.config.direction == "down" {

            // convert padding to ratio
            let fullPaddingStart = CGFloat(self.config.paddingStart) / imageSize.height * self.bounds.size.height
            let fullPaddingEnd = CGFloat(self.config.paddingEnd) / imageSize.height * self.bounds.size.height

            // top to bottom
            let offset = floor(progress * (self.bounds.size.height - fullPaddingEnd - fullPaddingStart) - fullPaddingStart)
            emptyImageContainer.frame =
                CGRect(x: 0, y: offset, width: self.bounds.size.width, height: self.bounds.size.height - offset)
            emptyImageView.frame =
                CGRect(x: 0, y: -offset, width: self.bounds.size.width, height: self.bounds.size.height)
            fullImageContainer.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: offset)
            fullImageView.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)

        } else if self.config.direction == "up" {

            // get padding
            let fullPaddingStart = CGFloat(self.config.paddingStart) / imageSize.height * self.bounds.size.height
            let fullPaddingEnd = CGFloat(self.config.paddingEnd) / imageSize.height * self.bounds.size.height

            // bottom to top
            let offsetRange = (self.bounds.size.height - fullPaddingEnd - fullPaddingStart)
            let offset = floor((1-progress) * offsetRange + fullPaddingEnd)

            emptyImageContainer.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: offset)
            emptyImageView.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
            fullImageContainer.frame =
                CGRect(x: 0, y: offset, width: self.bounds.size.width, height: self.bounds.size.height - offset)
            fullImageView.frame =
                CGRect(x: 0, y: -offset, width: self.bounds.size.width, height: self.bounds.size.height)

        } else if self.config.direction == "left" {

            //gGet padding
            let fullPaddingStart = CGFloat(self.config.paddingStart) / imageSize.width * self.bounds.size.width
            let fullPaddingEnd = CGFloat(self.config.paddingEnd) / imageSize.width * self.bounds.size.width

            // right to left
            let offsetRange = (self.bounds.size.width - fullPaddingEnd - fullPaddingStart)
            let offset = floor((1-progress) * offsetRange + fullPaddingEnd)
            emptyImageContainer.frame =
                CGRect(x: 0, y: 0, width: offset, height: self.bounds.size.height)
            emptyImageView.frame =
                CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
            fullImageContainer.frame =
                CGRect(x: offset, y: 0, width: self.bounds.size.width - offset, height: self.bounds.size.height)
            fullImageView.frame =
                CGRect(x: -offset, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)

        } else {

            // get padding
            let fullPaddingStart = CGFloat(self.config.paddingStart) / imageSize.width * self.bounds.size.width
            let fullPaddingEnd = CGFloat(self.config.paddingEnd) / imageSize.width * self.bounds.size.width

            // left to right
            let offset = floor(progress * (self.bounds.size.width - fullPaddingEnd - fullPaddingStart) - fullPaddingStart)
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

    // MARK: - Resource Management (TEMPORARY)

    // gather async events
    private let dispatchGroup = DispatchGroup()

    private func doResourceStuff(completion: @escaping (Error?) -> Void) {

        //FIXME: Use Config Section

        // ensure required resources are present
        guard
            let emptyImageResource = vatom.resources.first(where: { $0.name == "BaseImage" }),
            let fullImageResource = vatom.resources.first(where: { $0.name == "ActivatedImage" })
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
        emptyImageView.downloaded(from: emptyURL) { (_) in
            self.dispatchGroup.leave() // FIXME: Propagate error
        }
        fullImageView.downloaded(from: fullURL) { (_) in
            self.dispatchGroup.leave() // FIXME: Propagate error
        }

        dispatchGroup.notify(queue: .main) {
            completion(nil)
        }

    }

}
