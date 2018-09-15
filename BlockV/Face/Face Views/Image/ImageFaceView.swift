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
// - Experimenting
import AlamofireImage
import Nuke

let imageCache = AutoPurgingImageCache()

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

    // MARK: - Config

    /// Face model face configuration specification.
    private struct Config {

        enum Scale: String {
            case fit, fill
        }

        // defaults
        var scale: Scale = .fit
        var imageName: String = "ActivatedImage"

        /// Initialize using face configuration.
        init(_ faceConfig: JSON?) {

            guard let config = faceConfig else { return }

            // assign iff not nil
            if let scaleString = config["scale"]?.stringValue {
                self.scale ?= Config.Scale(rawValue: scaleString)
            }
            self.imageName ?= config["name"]?.stringValue
        
        }
    }

    /// Face configuration (immutable).
    ///
    /// It is best practice to keep this property immutable. The config of the face should not change over the lifetime
    /// of the face view.
    private let config: Config

    // MARK: - Initialization

    required init(vatom: VatomModel, faceModel: FaceModel) {

        // init face config
        self.config = Config(faceModel.properties.config)

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

       // guard animatedImageView.image != nil else { return }

        // check face config
        switch config.scale {
            case .fill: animatedImageView.contentMode = .scaleAspectFill
            case .fit:  animatedImageView.contentMode = .scaleAspectFit
        }

        //FXIME: Is this still needed?

//        // no face config supplied (try and do the right thing)
//        else if self.faceModel.properties.constraints.viewMode == "card" {
//            animatedImageView.contentMode = .scaleAspectFill
//        } else if image.size.width > animatedImageView.bounds.size.width ||
//            image.size.height > animatedImageView.bounds.size.height {
//            animatedImageView.contentMode = .scaleAspectFit
//        } else {
//            animatedImageView.contentMode = .center
//        }

    }

    // MARK: - Face View Lifecycle

    private var _timer: Timer?

    /// Begin loading the face view's content.
    func load(completion: @escaping (Error?) -> Void) {
        print(#function)

        // artificially wait so we can test the loader.
        self._timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in

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

    func prepareForReuse() {
        print(#function)
        self.animatedImageView.image = nil
    }

}

// MARK: - TEMPORARY

///FIXME: Replace with resource manager

extension ImageFaceView {

    func doResourceStuff(completion: @escaping (Error?) -> Void) {

        if let resourceModel = vatom.resources.first(where: { $0.name == config.imageName }) {
            if let url = try? BLOCKv.encodeURL(resourceModel.url) {
                
                // onUnload() { task.cancel }
        
                /*
                 Issues:
                 1. No cache control headers
                 2. Resouce urls must be encoded, this has the unfortunate effect of the url changing every so often,
                 which is a issue for caching.
                 3. Encoding the url is async, this means the loading images into views has some latency, this is not
                 good for visual responsiveness.
                 
                 TODO:
                 1. Cache using the unencoded url (to prevent the jwt from confusing the cache)
                 2. Expand cache to include data for 3d files.
                */

                // A - Simple extension

                //self.animatedImageView.downloaded(from: url, completion: completion)

                // B - Alamofire (which is using URLCache by default) - is this enough?,
                // are the server's cache headers good enough?

//                self.animatedImageView.af_setImage(withURL: url) { (_) in
//                    completion(nil)
//                }

                // create a scale filter
                //                let cgSize = CGSize(width: 300, height: 300)
                //                let sizeFilter = ScaledToSizeFilter(size: cgSize)
                //
                //                self.animatedImageView.af_setImage(withURL: url,
                //                                                   filter: sizeFilter) { _ in
                //                                                    completion(nil)
                //                }
                //

                // C - Nuke
                Nuke.loadImage(with: url, into: self.animatedImageView) { (_, _) in
                    completion(nil)
                }

            }
        }

    }

}

extension UIImageView {
    
    ///
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
    
    ///
    func downloaded(from link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode, completion: nil)
    }
}
