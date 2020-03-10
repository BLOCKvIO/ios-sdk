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
import CoreData
import GenericJSON

/*
 FaceCD
 - Flattened nesting to speed up property access.
 */

public final class FaceCD: NSManagedObject {
    
    @NSManaged public fileprivate(set) var id: UUID
    @NSManaged public fileprivate(set) var templateID: String
    @NSManaged public fileprivate(set) var isNative: Bool
    @NSManaged public fileprivate(set) var isWeb: Bool
    // properties
    @NSManaged public fileprivate(set) var propsDisplayURL: String
    @NSManaged public fileprivate(set) var propsConfigData: Data?
    @NSManaged public fileprivate(set) var propsResources: [String]
    
    // constraints
    @NSManaged public fileprivate(set) var constraintViewMode: String
    @NSManaged public fileprivate(set) var constraintPlatform: String
    // meta
    @NSManaged public fileprivate(set) var meta: MetaDataCD
    
    // MARK: - Relationships
    
    @NSManaged public fileprivate(set) var vatoms: Set<VatomCD>
    
    // MARK: - Transisent/computed/fixme
    
    @NSManaged fileprivate var configStorage: Data?

    //FIXME: This is very inefficient. Every access will trigger a transformation.
    public fileprivate(set) var propsConfig: JSON? {
        get {
            willAccessValue(forKey: "propsConfig")
            defer { didAccessValue(forKey: "propsConfig") }
            let decoder = JSONDecoder.blockv
            guard let data = configStorage else { return nil }
            let json = try! decoder.decode(JSON.self, from: data)
            return json
        }
        set {
            willChangeValue(forKey: "propsConfig")
            defer { didChangeValue(forKey: "propsConfig") }
            let encoder = JSONEncoder.blockv
            let data = try! encoder.encode(newValue)
            self.configStorage = data
        }
    }

}

extension FaceCD: Managed {}

extension FaceCD {
    
    static func insert(with faceModel: FaceModel, in context: NSManagedObjectContext) -> FaceCD {
        let faceCD: FaceCD = context.insertObject()
        faceCD.copyProps(from: faceModel, in: context)
        return faceCD
    }

    static func findOrCreate(with faceModel: FaceModel, in context: NSManagedObjectContext) -> FaceCD {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(id), faceModel.id)
        let faceCD: FaceCD = findOrCreate(in: context, matching: predicate) {
            $0.copyProps(from: faceModel, in: context)
        }
        return faceCD
    }
    
    private func copyProps(from model: FaceModel, in context: NSManagedObjectContext) {
        self.id = UUID(uuidString: model.id)! //FIXME: Remove uuid
        self.templateID = model.templateID
        self.meta = MetaDataCD.insert(with: model.meta, in: context)
        self.isNative = model.isNative
        self.isWeb = model.isWeb
        
        self.propsDisplayURL = model.properties.displayURL
        self.propsResources = model.properties.resources
        self.propsConfig = model.properties.config
        
        self.constraintPlatform = model.properties.constraints.platform
        self.constraintViewMode = model.properties.constraints.viewMode
    }
    
    //FIXME: Do we need an 'update' method?
    /// Convenience method to update a vatom object with a dictionary.
//    static func update(with faceModel: FaceModel, in context: NSManagedObjectContext) -> FaceCD {
//
//    }
    
}

//extension FaceCD: JSONUpdatable {
//
//    static func update(into context: NSManagedObjectContext, with descriptor: [String : Any]) throws -> FaceCD {
//        guard
//            let _id = descriptor["id"] as? String,
//            let _uuid = UUID(uuidString: _id),
//            let _templateID = descriptor["template"] as? String,
//            let _metaDescriptor = descriptor["meta"] as? [String: Any],
//            let _propertiesDescriptor = descriptor["properties"] as? [String: Any],
//            // props
//            let _propertiesDisplayURL = _propertiesDescriptor["display_url"] as? String,
//            let _propertiesConstraintsDescriptor = _propertiesDescriptor["constraints"] as? [String: Any],
//            // constraints
//            let _constraintsViewMode = _propertiesConstraintsDescriptor["view_mode"] as? String,
//            let _constraintsPlatform = _propertiesConstraintsDescriptor["platform"] as? String
//            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
//
//        // optionals
//        let _propertiesResources = _propertiesDescriptor["resources"] as? [String]
//        let _propertiesConfig = _propertiesDescriptor["config"] as? [String: Any]
//
//        let face: FaceCD = context.insertObject()
//        face.id = _uuid
//        face.templateID = _templateID
//        face.propsDisplayURL = _propertiesDisplayURL
//        face.propsConfig = _propertiesConfig
//        face.propsResources = _propertiesResources
//        face.constraintViewMode = _constraintsViewMode
//        face.constraintPlatform = _constraintsViewMode
//        face.meta = try MetaDataCD.update(into: context, with: _metaDescriptor)
//        // convenience
//        face.isNative   = _propertiesDisplayURL.hasPrefix("native://")
//        face.isWeb      = _propertiesDisplayURL.hasPrefix("https://")
//        return face
//    }
//
//}

extension FaceCD {
    
    public var structModel: FaceModel {
        
        let props = FaceModel.Properties(displayURL: self.propsDisplayURL,
                                         constraints: FaceModel.Properties.Constraints(viewMode: self.constraintViewMode,
                                                                                       platform: self.constraintPlatform),
                                         resources: self.propsResources,
                                         config: self.propsConfig)
        
        return FaceModel(id: self.id.uuidString,
                         templateID: self.templateID,
                         meta: self.meta.structModel,
                         properties: props,
                         isNative: self.isNative,
                         isWeb: self.isWeb)
    }
    
}
