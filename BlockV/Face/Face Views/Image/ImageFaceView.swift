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

/// Native Image face view
class ImageFaceView: FaceView {

    // MARK: - Face View Protocol

    class var displayURL: String { return "native://image" }

    // MARK: - Properties

    lazy var animatedImageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.clipsToBounds = true
        return imageView
    }()

    // MARK: - Initialization

    required init(vatom: VatomModel, faceModel: FaceModel) {
        super.init(vatom: vatom, faceModel: faceModel)

        // add image view
        self.addSubview(animatedImageView)
        animatedImageView.frame = self.bounds
        animatedImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // extract config
        self.extractConfig()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

    // MARK: - Face Config

    /// Face model face configuration specification.
    private struct Config {
        enum Scale: String {
            case fit, fill
        }
        var scale: Scale?
        var imageName: String
    }

    /// Face configuration (initialized with default values).
    ///
    /// - `scale`: defaults to `nil`.
    /// - `imageName`: defaults to `"ActivatedImage"`
    private var config = Config(scale: nil, imageName: "ActivatedImage")

    /// Extracts the face view's configuration.
    private func extractConfig() {
        // extract scale
        if let scaleString = self.faceModel.properties.config?["scale"]?.stringValue {
            config.scale = Config.Scale(rawValue: scaleString)!
        }
        // extract image name
        if let imageNameString = self.faceModel.properties.config?["name"]?.stringValue {
            config.imageName = imageNameString
        }
    }

    // MARK: - View Lifecylce

    override func layoutSubviews() {
        super.layoutSubviews()

        updateContentMode()
    }

    /// Update the content mode of the image view.
    ///
    /// Inspects the face config first and uses the scale if available. If no face config is found, a simple heuristic
    /// is used to choose the best content mode.
    private func updateContentMode() {

        guard let image = animatedImageView.image else { return }

        // check face config
        if let scale = config.scale {
            switch scale {
            case .fill: animatedImageView.contentMode = .scaleAspectFill
            case .fit: animatedImageView.contentMode = .scaleAspectFit
            }
            // no face config supplied (try and do the right thing)
        } else if self.faceModel.properties.constraints.viewMode == "card" {
            animatedImageView.contentMode = .scaleAspectFill
        } else if image.size.width > animatedImageView.bounds.size.width ||
            image.size.height > animatedImageView.bounds.size.height {
            animatedImageView.contentMode = .scaleAspectFit
        } else {
            animatedImageView.contentMode = .center
        }

    }

    // MARK: - Face View Lifecycle

    private var _timer: Timer?

    /// Begin loading the face view's content.
    func load(completion: @escaping (Error?) -> Void) {
        print(#function)

        // artificially wait so we can test the loader.
        self._timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            self.backgroundColor = .green

            // ugly completion handlers
            self.doResourceStuff(completion: completion)
        }

    }

    /// Respond to updates to the packaged vatom.
    func vatomUpdated(_ vatom: VatomModel) {
        print(#function)

        // replace current vatom
        self.vatom = vatom

        /*
         NOTE:
         The ImageFaceView does not need to respond to vAtom updates. All the properties this face uses are immutable
         once the vAtom has been emmited. Thus, no meaningful UI update can be made.
         */
    }

    /// Unload the face view.
    func unload() {
        print(#function)
    }

}

// MARK: - TEMPORARY

///FIXME: Replace with resource manager

extension ImageFaceView {

    func doResourceStuff(completion: @escaping (Error?) -> Void) {

        if let resourceModel = vatom.resources.first(where: { $0.name == config.imageName }) {
            if let url = try? BLOCKv.encodeURL(resourceModel.url) {
                self.animatedImageView.downloaded(from: url, completion: completion)
            }
        }

    }

}

extension UIImageView {
    func downloaded(from url: URL,
                    contentMode mode: UIViewContentMode = .scaleAspectFit,
                    completion: ((Error?) -> Void)? = nil) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else {
                    completion?(error)
                    return
            }

            DispatchQueue.main.async {
                self.image = image
                completion?(nil)
                printBV(info: "Image downloaded: \(url)")
            }
            }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode, completion: nil)
    }
}
