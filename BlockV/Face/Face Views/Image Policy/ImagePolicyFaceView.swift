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
class ImagePolicyFaceView: FaceView {

    class var displayURL: String { return "native://image-policy" }

    // MARK: - Properties

    lazy var animatedImageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.clipsToBounds = true
        return imageView
    }()

    public private(set) var isLoaded: Bool = false
    
    // MARK: - Config
    
    /*
     The config section of the image policy face does not lend itself to being typed so it is left as `JSON`.
     */

    // MARK: - Initialization

    required init(vatom: VatomModel, faceModel: FaceModel) {

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
    
    private var childCount: Int = 0

    /// Fetches the count of child vAtoms for the backing vAtom.
    ///
    /// - note:
    /// Asynchronous network operation.
    ///
    /// - Parameter completetion: Completion handler to call once the the child count is known.
    private func fetchChildCount(completion: ((Int?, Error?) -> Void)) {
        
        // FIXME: Hardcoded
        completion(1, nil)
        
    }
    
    /// Updates the displayed resources.
    ///
    /// - note:
    /// Asynchronous network operation.
    ///
    /// - Parameter completion: <#completion description#>
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
