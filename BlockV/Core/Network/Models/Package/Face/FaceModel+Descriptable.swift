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
import GenericJSON

//swiftlint:disable identifier_name

extension FaceModel: Descriptable {
    
    init(from descriptor: [String: Any]) throws {
        
        guard
            let _id = descriptor["id"] as? String,
            let _templateID = descriptor["template"] as? String,
            let _metaDescriptor = descriptor["meta"] as? [String: Any],
            let _propertiesDescriptor = descriptor["properties"] as? [String: Any]
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
        
        self.id = _id
        self.templateID = _templateID
        self.properties = try Properties(from: _propertiesDescriptor)
        self.meta = try MetaModel(from: _metaDescriptor)
        // convenience
        isNative   = properties.displayURL.hasPrefix("native://")
        isWeb      = properties.displayURL.hasPrefix("https://")
        
    }
    
}

extension FaceModel.Properties: Descriptable {
    
    init(from descriptor: [String: Any]) throws {
        guard
            let _displayURL = descriptor["display_url"] as? String,
            let _constraintsDescriptor = descriptor["constraints"] as? [String: Any],
            let _resources = descriptor["resources"] as? [String]
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
        
        let _config = descriptor["config"] as? [String: Any]
        
        self.displayURL = _displayURL
        self.constraints = try FaceModel.Properties.Constraints(from: _constraintsDescriptor)
        self.resources = _resources
        self.config = try? JSON(_config)
        
    }
    
}

extension FaceModel.Properties.Constraints: Descriptable {
    
    init(from descriptor: [String: Any]) throws {
        guard
            let _viewMode = descriptor["view_mode"] as? String,
            let _platform = descriptor["platform"] as? String
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
        
        self.viewMode = _viewMode
        self.platform = _platform
        
    }
    
}

extension MetaModel: Descriptable {
    
    init(from descriptor: [String: Any]) throws {
        guard
            let _createdBy = descriptor["created_by"] as? String,
            let _dataType = descriptor["data_type"] as? String,
            let _whenCreated = descriptor["when_created"] as? String,
            let _whenModified = descriptor["when_modified"] as? String,
            let _whenCreatedDate = DateFormatter.blockvDateFormatter.date(from: _whenCreated),
            let _whenModifiedDate = DateFormatter.blockvDateFormatter.date(from: _whenModified)
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
        
        self.init(createdBy: _createdBy,
                  dataType: _dataType,
                  whenCreated: _whenCreatedDate,
                  whenModified: _whenModifiedDate)
        
    }
    
}
