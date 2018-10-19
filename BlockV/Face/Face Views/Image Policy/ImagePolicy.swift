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

/// Protocol image policies should conform to.
protocol ImagePolicy {
    /// Name of the resource the policy requires to be displayed.
    var resourceName: String { get }
}

struct FaceConfig {
    
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
    
    init(from descriptor: [String : Any]) throws {
        
        guard let imagePolicyDescriptors = descriptor["image_policy"] as? [[String: Any]] else {
            throw VatomFaceError.invalidPrivateConfigutration //TODO: This could be more fine granined.
        }
        
        // loop over all the polices
        for imagePolicyDescriptor in imagePolicyDescriptors {
            
            // ensure a resource name is present
            guard let resourceName = imagePolicyDescriptor["resource"] as? String else {
                // skip this policy
                continue
            }
            
            // child count
            if let countMax = imagePolicyDescriptor["count_max"] as? Int {
                let childCountPolicy = ChildCount(resourceName: resourceName, countMax: countMax)
                self.policies.append(childCountPolicy)
                continue
            }
                // field lookup
            else if let field = imagePolicyDescriptor["field"] as? String,
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
