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
import FLAnimatedImage
import Nuke
import GenericJSON

/// Native Image face view
///
/// Displays a resource based on the frist matching item in the policy array.
///
/// ### Owned vs. Unowned Vatoms
///
/// The real-time addition and removal of child vatoms is only tracked for vatoms the user owns. Since this face view
/// is dependent on child relationships, it's representation of unowned vatoms may be inaccurate.
class ImagePolicyFaceView: FaceView {

    class var displayURL: String { return "native://image-policy" }

    // MARK: - Properties

    lazy var animatedImageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    public private(set) var isLoaded: Bool = false

    // MARK: - Config

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

        // enable animated images
        ImagePipeline.Configuration.isAnimatedImageDataEnabled = true

        // add image view
        self.addSubview(animatedImageView)
        animatedImageView.frame = self.bounds

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

    // MARK: - Face View Lifecycle

    private var storedCompletion: ((Error?) -> Void)?

    /// Begins loading the face view's content.
    func load(completion: ((Error?) -> Void)?) {
        // reset content
        self.reset()
        // store the completion
        self.storedCompletion = completion
        // flag a known-bounds layout
        self.requiresBoundsBasedSetup = true
    }

    /// Updates the backing Vatom and loads the new state.
    ///
    /// The VVLC ensures the vatom will share the same template variation. This means the vatom will have the same
    /// resources but the state of the face (e.g. which recsources it is showing) may be different.
    func vatomChanged(_ vatom: VatomModel) {

        if self.vatom.id == vatom.id {
            // replace vatom, update UI
            self.vatom = vatom

        } else {
            // replace vatom, reset and update UI
            self.vatom = vatom
            self.reset()
        }
        // flag a known-bounds layout
        self.requiresBoundsBasedSetup = true

    }

    /// Resets the contents of the face view.
    private func reset() {
        self.animatedImageView.image = nil
        self.animatedImageView.animatedImage = nil
    }

    /// Unload face view. Reset all content.
    func unload() {
        self.reset()
        //TODO: Cancel all downloads
    }

    /// Updates interface with local state.
    override func setupWithBounds() {
        super.setupWithBounds()

        // extract resource
        let resourceName = self.extractImageName()
        // update state
        self.updateImageView(withResource: resourceName) { [weak self] error in

            guard let self = self else { return }
            // inform delegate of load completion
            if let error = error {
                self.isLoaded = false
                self.storedCompletion?(error)
            } else {
                self.isLoaded = true
                self.storedCompletion?(nil)
            }
        }

    }

    // MARK: - Face Code

    /// Current count of child vAtoms.
    private var currentChildCount: Int {
        // inspect cached children
        return (try? self.vatom.listCachedChildren().count) ?? 0
    }

    /// Update the face view using *local* data.
    ///
    /// Do not call directly. Rather call `debouncedUpdateUI()`.
    ///
    /// Loops over the array of image policies - stops if a policy's critera are satisfied.
    private func extractImageName() -> String {

        // loop over polices - use first passing policy
        for policy in config.policies {

            if let policy = policy as? Config.ChildCount {
                // check criteria
                if policy.countMax >= currentChildCount {
                    // update image
                    return policy.resourceName
                }

            } else if let policy = policy as? Config.FieldLookup {

                if let vatomValue = self.vatom.valueForKeyPath(policy.field) {
                    if vatomValue == policy.value {
                        // update image
                        //print(">>:: vAtom Value: \(vatomValue) | Policy Value: \(policy.value)\n")
                        return policy.resourceName
                    }
                }

            } else if policy is Config.Fallback {
                // update image
                return policy.resourceName
            }

        }

        // This is the last resort fallback (evaluated *after* the face developer assigned fallback).
        return "ActivatedImage"

    }

    // MARK: - Resources

    /// Updates image view with the specified resource.
    ///
    /// - note:
    /// Asynchronous network operation.
    ///
    /// - Parameter completion: The completion handler is called once the image is downloaded (or an error is
    ///                         encountered).
    private func updateImageView(withResource resourceName: String, completion: ((Error?) -> Void)?) {

        // extract resource model
        guard let resourceModel = vatom.props.resources.first(where: { $0.name == resourceName }) else {
            completion?(FaceError.missingVatomResource)
            return
        }

        let resize = ImageProcessor.Resize(size: self.bounds.size, contentMode: .aspectFit)
        let request = BVImageRequest(url: resourceModel.url, processors: [resize])
        // load iamge
        ImageDownloader.loadImage(with: request, into: self.animatedImageView) { result in
            self.isLoaded = true
            do {
                try result.get()
                completion?(nil)
            } catch {
                os_log("Failed to load: %@", log: .vatomView, type: .error, resourceModel.url.description)
                completion?(error)
            }
        }

    }

}

// MARK: - Image Policy

/// Protocol image policies should conform to.
private protocol ImagePolicy {
    /// Name of the resource the policy requires to be displayed.
    var resourceName: String { get }
}

private extension ImagePolicyFaceView {

    /*
     Example Payload
     
     {
     "image_policy": [
     {
     "count_max": 0,
     "resource": "ActivatedImage"
     },
     {
     "count_max": 1,
     "resource": "ActivatedImage1"
     },
     {
     "field": "private.<some_property>",
     "resource": "<some_resource_name>",
     "value": "<seme_value>"
     },
     {
     "resource": "ActivatedImage2"
     }
     ]
     }
     
     */

    struct Config {

        // MARK: - Structs

        /*
         Strongly typed struct for each known image policy type.
         */

        struct ChildCount: ImagePolicy {
            /// Name of the resource the policy requires for display.
            let resourceName: String
            /// Maximum number of children for which the policy is valid.
            let countMax: Int
        }

        struct FieldLookup: ImagePolicy {
            /// Name of the resource the policy requires for display.
            let resourceName: String
            /// Property name to lookup on the vAtom.
            let field: String
            /// Property value to campare to.
            let value: JSON
        }

        struct Fallback: ImagePolicy {
            /// Name of the resource the policy requires for display.
            let resourceName: String
        }

        /// Array of image policies
        var policies: [ImagePolicy] = []

        // MARK: - Initializer

        /// Initialize using default values.
        init() {}

        /// Initialize using face configuration.
        init(_ faceConfig: JSON) {

            // ensure an image policy array is present
            guard let imagePolicyDescriptors = faceConfig["image_policy"]?.arrayValue else {
                return
            }

            // loop over all the polices
            for imagePolicyDescriptor in imagePolicyDescriptors {

                // ensure a resource name is present
                guard let resourceName = imagePolicyDescriptor["resource"]?.stringValue else {
                    // skip this policy
                    continue
                }

                // child count
                if let countMax = imagePolicyDescriptor["count_max"]?.doubleValue {
                    let childCountPolicy = ChildCount(resourceName: resourceName, countMax: Int(countMax))
                    self.policies.append(childCountPolicy)
                    continue
                }
                    // field lookup
                else if let field = imagePolicyDescriptor["field"]?.stringValue,
                    let value = imagePolicyDescriptor["value"] {
                    let fieldLookupPolicy = FieldLookup(resourceName: resourceName, field: field, value: value)
                    self.policies.append(fieldLookupPolicy)
                    continue
                }
                    // fallback policy
                else {
                    let fallbackPolicy = Fallback(resourceName: resourceName)
                    self.policies.append(fallbackPolicy)
                }

            }

        }

    }

}
