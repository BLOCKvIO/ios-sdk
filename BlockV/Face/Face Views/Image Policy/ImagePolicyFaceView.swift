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
///
/// Displays a resource based on the frist matching item in the policy array.
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
        super.init(vatom: vatom, faceModel: faceModel)
        
        // add image view
        self.addSubview(animatedImageView)
        animatedImageView.frame = self.bounds
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
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
    
    // MARK: - Face Code
    
    /*
     Note:
     The `vatomStateChanged()` method called by `VatomView` does not handle child vatom updates.
     A `VatomObserver` class is used to receive these events. This is required for the Child Count policy type.
     */
    
    /// Class responsible for observing changes related backing vAtom.
    private var vatomObserver: VatomObserver
    
    /// Current count of child vAtoms.
    private var currentChildCount: Int {
        return vatomObserver.childVatomIDs.count
    }
    
    /// Update the face view using *local* data.
    ///
    /// Loops over the array of image policies - stops if a policie's critera are satisfied and downloads the required
    /// resource and updates the image view.
    private func updateUI() {
        
        // loop over polices - use first passing policy
        for policy in config.policies {
            
            if let policy = policy as? Config.ChildCount {
                // check criteria
                if policy.countMax >= currentChildCount {
                    // update image
                    fetchResourceNamed(policy.resourceName)
                    break
                }
                
            } else if let policy = policy as? Config.FieldLookup {
                
                // create key path and split into head and tail
                // only private section lookups are allowed
                guard let component = KeyPath(policy.field).headAndTail(),
                    component.head == "private",
                    let vatomValue = self.vatom.properties[keyPath: component.tail] else {
                        continue
                }
                
                if  compare(vatomValue, policy.value) {
                    // update image
                    //print(">>:: vAtom Value: \(vatomValue) | Policy Value: \(policy.value)\n")
                    fetchResourceNamed(policy.resourceName)
                    break
                }
                
            } else if policy is Config.Fallback {
                // update image
                fetchResourceNamed(policy.resourceName)
                break
            }
            
        }
        
    }
    
    // MARK: - Resources
    
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
            let value: Any
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
                if let countMax = imagePolicyDescriptor["count_max"]?.floatValue {
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
            
            // This is the last resort fallback (evaluated *after* the face developer assigned fallback).
            let activatedImageFallbackPolicy = Fallback(resourceName: "ActivatedImage")
            self.policies.append(activatedImageFallbackPolicy)
            
        }
        
    }
    
}
