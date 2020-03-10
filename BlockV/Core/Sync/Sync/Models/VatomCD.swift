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
import CoreLocation
import GenericJSON

public protocol BVStructable {
    
    var model: Self { get }
    
}

/*
 Notes:
 - Here we add the to-many relationship to resource since we want to traverse this in code.
 */

public final class VatomCD: NSManagedObject {
    
    // top level
    @NSManaged public fileprivate(set) var id: String
    @NSManaged public fileprivate(set) var version: String
    @NSManaged public fileprivate(set) var isUnpublished: Bool
    @NSManaged public fileprivate(set) var whenCreated: Date
    @NSManaged public fileprivate(set) var whenModified: Date
    @NSManaged public fileprivate(set) var whenAdded: Date
    @NSManaged public fileprivate(set) var sync: Int
    
    // root constants
    @NSManaged public fileprivate(set) var author: String
    @NSManaged public fileprivate(set) var rootType: String
    @NSManaged public fileprivate(set) var templateID: String
    @NSManaged public fileprivate(set) var templateVariationID: String
    @NSManaged public fileprivate(set) var publisherFQDN: String
    @NSManaged public fileprivate(set) var title: String
    @NSManaged public fileprivate(set) var descriptionInfo: String
    
    // root variables
    @NSManaged public fileprivate(set) var category: String
    @NSManaged public fileprivate(set) var childPolicy: Set<VatomChildPolicyCD>
    @NSManaged public fileprivate(set) var clonedFrom: String
    @NSManaged public fileprivate(set) var cloningScore: Double
    @NSManaged public fileprivate(set) var commerce: VatomCommerceCD
    @NSManaged public fileprivate(set) var isInContract: Bool
    @NSManaged public fileprivate(set) var inContractWith: String
    @NSManaged public fileprivate(set) var notifyMessage: String
    @NSManaged public fileprivate(set) var numberDirectClones: Int
    @NSManaged public fileprivate(set) var owner: String
    @NSManaged public fileprivate(set) var parentID: String
    @NSManaged public fileprivate(set) var transferredBy: String
    @NSManaged public fileprivate(set) var visibility: VatomVisibilityCD
    @NSManaged public fileprivate(set) var tags: Set<TagCD>

    @NSManaged public fileprivate(set) var isAcquirable: Bool
    @NSManaged public fileprivate(set) var isRedeemable: Bool
    @NSManaged public fileprivate(set) var isDisabled: Bool
    @NSManaged public fileprivate(set) var isDropped: Bool
    @NSManaged public fileprivate(set) var isTradeable: Bool
    @NSManaged public fileprivate(set) var isTransferable: Bool
    
    @NSManaged fileprivate var latitude: Double
    @NSManaged fileprivate var longitude: Double
    
    public var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // I've made these internally settable, since a separate object will likely do the association.
    @NSManaged public internal(set) var faces: Set<FaceCD>
    @NSManaged public internal(set) var actions: Set<ActionCD>
    @NSManaged public internal(set) var children: Set<VatomCD>
    // this is optional due to a core data requirement about unique contraints and non-optional to-one relationships
    @NSManaged public internal(set) var parent: VatomCD?

    @NSManaged public fileprivate(set) var resources: Set<ResourceCD>
    
    // MARK: - Private
    
    @NSManaged fileprivate var cryptoEOSData: Data?
    @NSManaged fileprivate var cryptoETHData: Data?
    
    // JSON: https://youtu.be/w7tFF7IfKVk?t=1189
    //FIXME: Where does the 'key' get defined?
    //FIXME: JSON will have to be stored as data...
    
    // This is very inefficient. Every access will trigger a transformation.
//    public var `private`: JSON? {
//        get {
//            willAccessValue(forKey: "json")
//            defer { didAccessValue(forKey: "json") }
//            return primitiveValue(forKey: "json") as? JSON //FIXME: Will CD be fine with this type?
//        }
//        set {
//            willChangeValue(forKey: "json")
//            defer { didChangeValue(forKey: "json") }
//            setPrimitiveValue(newValue, forKey: "json") //FIXME: Crashes when setting. The type is not known to CD.
//        }
//    }
    
    // OR
    
    @NSManaged fileprivate var privateStorage: Data?
    
    //FIXME: This is very inefficient. Every access will trigger a transformation.
    public fileprivate(set) var `private`: JSON? {
        get {
            willAccessValue(forKey: "private")
            defer { didAccessValue(forKey: "private") }
            let decoder = JSONDecoder.blockv
            guard let data = privateStorage else { return nil }
            print("xxx", "reading json", String(data: data, encoding: .utf8)!)
            let json = try! decoder.decode(JSON.self, from: data)
            return json
        }
        set {
            willChangeValue(forKey: "private")
            defer { didChangeValue(forKey: "private") }
            let encoder = JSONEncoder.blockv
            let data = try! encoder.encode(newValue)
            print("xxx"," setting json", newValue)
            self.privateStorage = data
        }
    }
    
    public fileprivate(set) var cryptoETH: JSON?
    public fileprivate(set) var cryptoEOS: JSON?
    
    
    /*
     This is tough.
     
     The options are:
     1. Abondon the JSON type and use [String: Any].
     - All the type safety, ease-of-use, and Codable support is lost.
     - Core data will use the type as `Transformable` and back it with a plist.
     
     2. Keep JSON, but write some kind of indirection layer (custom accessor) which shims into a data blob.
     - This means there will be some bookkeeping to ensure the exposed type and the storage are kept in sync.
     
     // Error: Property cannot be marked @NSManaged because its type cannot be represented in Objective-C
     //@NSManaged fileprivate(set) var json: JSON
     
     // This will be stored as a plist (not the most efficient)
     // Also, this means dropping SwiftyJSON
     //    @NSManaged fileprivate(set) var `private`: JSON?
     
     Rather:
     1. ValueTransformer // won't work cause json is not
     2. NSCoding + Transformable // not possible?
     3. Custom Accessor (lazy access)
     > This looks to be the only option, and will need perf improvements.
     
     // Experiemnt B
     
     // persisted
     @NSManaged fileprivate var privateStorage: Data
     
     // transient non-persisted
     @NSManaged fileprivate var primativePrivate: [String: Any]?
     */
    
}

extension VatomCD: Managed {
    
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        //TODO: isn't this better?
        //        return[NSSortDescriptor(keyPath: \VatomCD.whenModified, ascending: false)]
        return [NSSortDescriptor(key:  #keyPath(whenModified), ascending: false)]
//        return [NSSortDescriptor(key:  #keyPath(whenAdded), ascending: false)] //TODO: Use this
    }
    
    public static var defaultPredicate: NSPredicate {
        return notMarkedForDeletionPredicate
    }
    
}

extension VatomCD: DelayedDeletable {
    @NSManaged public var markedForDeletionDate: Date?
}

extension VatomCD: RemoteDeletable {
    @NSManaged public var markedForRemoteDeletion: Bool
}

extension VatomCD {
    
    /*
     ISSUE
     Model based initializer cannot work due to swift-only types, e.g. JSON. These would have to be serialized to
     data and back.
     - It looks like the pattern of init the core data model using a model parsed with codable will not work if
     there are types which are not representable in Objective-C, e.g. JSON.
     - VatomModel models freefrom json using GenericJSON, this would have to be shoehorned into CoreData somehow.
     */
    
    /*
     # Thoughts
     
     I'm not sure when to use `insert` and when to use `findOrCreate`. My intuition tells me that when inserting from
     remote I should use `insert` for perf. reasons. `findOrCreate` will reach into the SQL tier each time.
     */
    
    /// Creates a new vatom managed object and configures it with the properties of the `vatomModel`.
    ///
    /// Does not execute a fetch request.
    static func insert(with vatomModel: VatomModel, in context: NSManagedObjectContext) -> VatomCD {
        let vatomCD: VatomCD = context.insertObject()
        vatomCD.copyProps(from: vatomModel, in: context)
        return vatomCD
    }
    
    /// Convenience create or update a vatom object.
    ///
    /// Executes a fetch request to retrieve the object. If not found, a new managed object is created.
    static func findOrCreate(with vatomModel: VatomModel, in context: NSManagedObjectContext) -> VatomCD {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(id), vatomModel.id)
        let vatomCD = findOrCreate(in: context, matching: predicate) {
            $0.copyProps(from: vatomModel, in: context)
        }
        return vatomCD
    }
    
    private func copyProps(from model: VatomModel, in context: NSManagedObjectContext) {
        
        // top level
        self.id = model.id
        self.version = model.version
        self.whenCreated = model.whenCreated
        self.whenModified = model.whenModified
        self.whenAdded = model.whenAdded
        self.isUnpublished = model.isUnpublished
        self.sync = Int(model.sync) //FIXME: Remove UInt
        
        // root-type constants
        self.author = model.props.author
        self.rootType = model.props.rootType
        self.templateID = model.props.templateID
        self.templateVariationID = model.props.templateVariationID
        self.publisherFQDN = model.props.publisherFQDN
        self.title = model.props.title
        self.descriptionInfo = model.props.description
        
        // root-type variables
        self.category = model.props.category
        self.clonedFrom = model.props.clonedFrom
        self.cloningScore = model.props.cloningScore
        self.commerce = VatomCommerceCD.insert(with: model.props.commerce, in: context)
        self.inContractWith = model.props.inContractWith
        self.isInContract = model.props.isInContract
        self.notifyMessage = model.props.notifyMessage
        self.numberDirectClones = model.props.numberDirectClones
        self.owner = model.props.owner
        self.parentID = model.props.parentID
        self.transferredBy = model.props.transferredBy
        
        self.isAcquirable = model.props.isAcquirable
        self.isRedeemable = model.props.isRedeemable
        self.isDisabled = model.props.isDisabled
        self.isDropped = model.props.isDropped
        self.isTradeable = model.props.isTradeable
        self.isTransferable = model.props.isTransferable
        self.visibility = VatomVisibilityCD.insert(with: model.props.visibility, in: context)
        
        model.props.childPolicy.forEach {
            let childPolicy = VatomChildPolicyCD.insert(with: $0, in: context)
            self.childPolicy.insert(childPolicy)
        }
        
        self.resources = Set<ResourceCD>() //FIXME: What happends with uniqueness contraints?
        model.props.resources.forEach {
            let resource = ResourceCD.findOrCreateResource(in: context, with: $0)
            self.resources.insert(resource)
        }
        
        model.props.tags.forEach {
            TagCD.insert(tag: $0, in: context) //FIXME: This is incomplete, vatom association is needed
        }
            
        self.latitude = model.props.geoPosition.coordinates[1]
        self.longitude = model.props.geoPosition.coordinates[0]
        
        print("xxx", "model.private", model.private)
        self.private = model.private
        
        //        vatom.cryptoEOS = ???
        //        vatom.cryptoETH = ???
        
        //         vatom.faces = Set<FaceCD>()
        //         vatom.actions = Set<ActionCD>()
        
    }
    
}

// MARK: - Vatom Visibility

public final class VatomVisibilityCD: NSManagedObject, Managed {
    
    @NSManaged public fileprivate(set) var type: String
    @NSManaged public fileprivate(set) var value: String
    
    static func insert(with visibilityModel: RootProperties.Visibility, in context: NSManagedObjectContext) -> VatomVisibilityCD {
        let visibility: VatomVisibilityCD = context.insertObject()
        visibility.type = visibilityModel.type
        visibility.value = visibilityModel.value
        return visibility
    }
    
}

extension VatomVisibilityCD {
    
    var structModel: RootProperties.Visibility {
        return RootProperties.Visibility(type: self.type, value: self.value)
    }
    
}

// MARK: - Vatom Commerce

public final class VatomCommerceCD: NSManagedObject, Managed {
    
    @NSManaged public fileprivate(set) var pricing: VatomPricingCD
    
    static func insert(with commerceModel: RootProperties.Commerce, in context: NSManagedObjectContext) -> VatomCommerceCD {
        let commerce: VatomCommerceCD = context.insertObject()
        commerce.pricing = VatomPricingCD.insert(with: commerceModel.pricing, in: context)
        return commerce
    }
    
}

extension VatomCommerceCD {
    
    public var structModel: RootProperties.Commerce {
        let pricing = VatomPricing(pricingType: self.pricing.pricingType,
                                   currency: self.pricing.currency,
                                   price: self.pricing.price,
                                   validFrom: self.pricing.validFrom,
                                   validThrough: self.pricing.validThrough,
                                   isVatIncluded: self.pricing.isVatIncluded)
        return RootProperties.Commerce(pricing: pricing)
    }
    
}

// MARK: - Vatom Child Policy

public final class VatomChildPolicyCD: NSManagedObject, Managed {
    
    @NSManaged public fileprivate(set) var count: Int
    @NSManaged public fileprivate(set) var templateVariationID: String
    @NSManaged public fileprivate(set) var creationPolicy: VatomCreationPolicyCD
    
    //FIXME: Is this right? Shouldn't we just be creating it? or should we be updating an exisitng entity?
    
    /// Convenience method to update a vatom object with a dictionary.
    static func insert(with childPolicyModel: VatomChildPolicy, in context: NSManagedObjectContext) -> VatomChildPolicyCD {
        let childPolicy: VatomChildPolicyCD = context.insertObject()
        childPolicy.count = childPolicyModel.count
        childPolicy.templateVariationID = childPolicyModel.templateVariationID
        childPolicy.creationPolicy = VatomCreationPolicyCD.insert(with: childPolicyModel.creationPolicy, in: context)
        return childPolicy
    }
    
}

public extension VatomChildPolicyCD {
    
    var structModel: VatomChildPolicy {
        VatomChildPolicy(count: self.count,
                         creationPolicy: self.creationPolicy.structModel,
                         templateVariationID: self.templateVariationID)
    }
    
}

// MARK: - Vatom Creation Policy

public final class VatomCreationPolicyCD: NSManagedObject, Managed {
    
    @NSManaged public fileprivate(set) var autoCreate: String
    @NSManaged public fileprivate(set) var autoCreateCount: Int
    @NSManaged public fileprivate(set) var autoCreateCountRandom: Bool
    @NSManaged public fileprivate(set) var enforcePolicyCountMax: Bool
    @NSManaged public fileprivate(set) var enforcePolicyCountMin: Bool
    @NSManaged public fileprivate(set) var policyCountMax: Int
    @NSManaged public fileprivate(set) var policyCountMin: Int
    
    static func insert(with creationPolicyModel: VatomChildPolicy.CreationPolicy, in context: NSManagedObjectContext) -> VatomCreationPolicyCD {
        let creationPolicy: VatomCreationPolicyCD = context.insertObject()
        creationPolicy.autoCreate = creationPolicyModel.autoCreate
        creationPolicy.autoCreateCount = creationPolicyModel.autoCreateCount
        creationPolicy.autoCreateCountRandom = creationPolicyModel.autoCreateCountRandom
        creationPolicy.enforcePolicyCountMax = creationPolicyModel.enforcePolicyCountMax
        creationPolicy.enforcePolicyCountMin = creationPolicyModel.enforcePolicyCountMin
        creationPolicy.policyCountMax = creationPolicyModel.policyCountMax
        creationPolicy.policyCountMin = creationPolicyModel.policyCountMin
        return creationPolicy
    }
    
}

extension VatomCreationPolicyCD {
    
    var structModel: VatomChildPolicy.CreationPolicy {
        return VatomChildPolicy.CreationPolicy(autoCreate: self.autoCreate,
                                               autoCreateCount: self.autoCreateCount,
                                               autoCreateCountRandom: self.autoCreateCountRandom,
                                               enforcePolicyCountMax: self.enforcePolicyCountMax,
                                               enforcePolicyCountMin: self.enforcePolicyCountMin,
                                               policyCountMax: self.policyCountMax,
                                               policyCountMin: self.policyCountMin)
    }
    
}

// MARK: - Vatom Pricing

public final class VatomPricingCD: NSManagedObject, Managed {
    
    @NSManaged public fileprivate(set) var pricingType: String
    @NSManaged public fileprivate(set) var currency: String
    @NSManaged public fileprivate(set) var price: String
    @NSManaged public fileprivate(set) var validFrom: String
    @NSManaged public fileprivate(set) var validThrough: String
    @NSManaged public fileprivate(set) var isVatIncluded: Bool
    
    static func insert(with pricingModel: VatomPricing, in context: NSManagedObjectContext) -> VatomPricingCD {
        let vatomPricing: VatomPricingCD = context.insertObject()
        vatomPricing.pricingType = pricingModel.pricingType
        vatomPricing.currency = pricingModel.currency
        vatomPricing.price = pricingModel.price
        vatomPricing.validFrom = pricingModel.validFrom
        vatomPricing.validThrough = pricingModel.validThrough
        vatomPricing.isVatIncluded = pricingModel.isVatIncluded
        return vatomPricing
    }
    
}

extension VatomPricingCD {
    
    var structModel: VatomPricing {
        return VatomPricing(pricingType: self.pricingType,
                            currency: self.currency,
                            price: self.price,
                            validFrom: self.validFrom,
                            validThrough: self.validThrough,
                            isVatIncluded: self.isVatIncluded)
    }
}


// MARK: - JSONUpdatable

//extension VatomCD: JSONUpdatable {
//    
//    /// Convenience method to update a vatom object.
//    static func update(into context: NSManagedObjectContext, with descriptor: [String: Any]) throws -> VatomCD {
//        let vatom: VatomCD = context.insertObject()
//        guard
//            let _id                     = descriptor["id"] as? String,
//            let _version                = descriptor["version"] as? String,
//            let _whenCreated            = descriptor["when_created"] as? String,
//            let _whenModified           = descriptor["when_modified"] as? String,
//            let _whenAdded              = descriptor["when_added"] as? String,
//            let _private                = descriptor["private"] as? [String: Any],
//            let _rootDescriptor         = descriptor["vAtom::vAtomType"] as? [String: Any],
//            let _sync                   = descriptor["sync"] as? Int,
//            
//            let _author                 = _rootDescriptor["author"] as? String,
//            let _rootType               = _rootDescriptor["root_type"] as? String,
//            let _templateID             = _rootDescriptor["template"] as? String,
//            let _templateVariationID    = _rootDescriptor["template_variation"] as? String,
//            let _publisherFQDN          = _rootDescriptor["publisher_fqdn"] as? String,
//            let _title                  = _rootDescriptor["title"] as? String,
//            let _description            = _rootDescriptor["description"] as? String,
//            
//            let _category               = _rootDescriptor["category"] as? String,
//            let _clonedFrom             = _rootDescriptor["cloned_from"] as? String,
//            let _cloningScore           = _rootDescriptor["cloning_score"] as? Double,
//            let _commerceDescriptor     = _rootDescriptor["commerce"] as? [String: Any],
//            let _isInContract           = _rootDescriptor["in_contract"] as? Bool,
//            let _inContractWith         = _rootDescriptor["in_contract_with"] as? String,
//            let _notifyMessage          = _rootDescriptor["notify_msg"] as? String,
//            let _numberDirectClones     = _rootDescriptor["num_direct_clones"] as? Int,
//            let _owner                  = _rootDescriptor["owner"] as? String,
//            let _parentID               = _rootDescriptor["parent_id"] as? String,
//            let _transferredBy          = _rootDescriptor["transferred_by"] as? String,
//            let _visibilityDescriptor   = _rootDescriptor["visibility"] as? [String: Any],
//            
//            let _isAcquirable           = _rootDescriptor["acquirable"] as? Bool,
//            let _isRedeemable           = _rootDescriptor["redeemable"] as? Bool,
//            let _isDisabled             = _rootDescriptor["disabled"] as? Bool,
//            let _isDropped              = _rootDescriptor["dropped"] as? Bool,
//            let _isTradeable            = _rootDescriptor["tradeable"] as? Bool,
//            let _isTransferable         = _rootDescriptor["transferable"] as? Bool,
//            
//            let _geoPositionDescriptor  = _rootDescriptor["geo_pos"] as? [String: Any],
//            let _coordinates            = _geoPositionDescriptor["coordinates"] as? [Double],
//            let _resourceDescriptors    = _rootDescriptor["resources"] as? [[String: Any]]
//            
//            else { throw BVError.modelDecoding(reason: "Model decoding failed: \(type(of: self))") }
//        
//        // decode if present
//        let _childPolicyDescriptor  = _rootDescriptor["child_policy"] as? [[String: Any]] ?? []
//        let _tags                   = _rootDescriptor["tags"] as? [String] ?? []
//        
//        
//        vatom.id = _id
//        vatom.version = _version
//        vatom.whenCreated = DateFormatter.blockvDateFormatter.date(from: _whenCreated)! //FIXME: force
//        vatom.whenModified = DateFormatter.blockvDateFormatter.date(from: _whenModified)! //FIXME: force
//        vatom.whenAdded = DateFormatter.blockvDateFormatter.date(from: _whenAdded)! //FIXME: force
//        vatom.isUnpublished = (descriptor["unpublished"] as? Bool) ?? false
//        vatom.sync = _sync
//        
//        // root-type constants
//        vatom.author = _author
//        vatom.rootType = _rootType
//        vatom.templateID = _templateID
//        vatom.templateVariationID = _templateVariationID
//        vatom.publisherFQDN = _publisherFQDN
//        vatom.title = _title
//        vatom.descriptionInfo = _description
//        vatom.category = _category
//        
//        vatom.clonedFrom = _clonedFrom
//        vatom.cloningScore = _cloningScore
//        vatom.commerce = try VatomCommerceCD.update(into: context, with: _commerceDescriptor)
//        vatom.isInContract = _isInContract
//        vatom.inContractWith = _inContractWith
//        vatom.notifyMessage = _notifyMessage
//        vatom.numberDirectClones = _numberDirectClones
//        vatom.owner = _owner
//        vatom.parentID = _parentID
//        vatom.tags = _tags
//        vatom.transferredBy = _transferredBy
//        vatom.visibility = try VatomVisibilityCD.update(into: context, with: _visibilityDescriptor)
//        
//        vatom.isAcquirable = _isAcquirable
//        vatom.isRedeemable = _isRedeemable
//        vatom.isDisabled = _isDisabled
//        vatom.isDropped = _isDropped
//        vatom.isTradeable = _isTradeable
//        vatom.isTransferable = _isTransferable
//        
//        _childPolicyDescriptor.forEach {
//            if let childPolicy = try? VatomChildPolicyCD.update(into: context, with: $0) {
//                vatom.childPolicy.insert(childPolicy)
//            }
//        }
//        
//        vatom.resources = Set<ResourceCD>()
//        _resourceDescriptors.forEach {
//            if let resource = try? ResourceCD.findOrCreateResource(in: context, with: $0) {
//                vatom.resources.insert(resource)
//            }
//        }
//        
//        vatom.latitude =  _coordinates[1]
//        vatom.longitude = _coordinates[0]
//        
//        // flexible schema
//        vatom.private = descriptor["private"] as? [String: Any]
//        vatom.cryptoETH = descriptor["eth"] as? [String: Any]
//        vatom.cryptoEOS = descriptor["eos"] as? [String: Any]
//        
//        /*
//         Assumption Broken 🧐
//         I thought I'd have to create an empty set for each of the non-optional relationships, but it seems xcode is
//         doing it on our behalf?
//         */
//        
//        // vatom.template = TemplateCD.findOrCreate
//        // vatom.faces = Set<FaceCD>()
//        // vatom.actions = Set<ActionCD>()
//        
//        return vatom
//    }
//    
//}
//
//extension VatomVisibilityCD: JSONUpdatable {
//    
//    static func update(into context: NSManagedObjectContext, with descriptor: [String: Any]) throws -> VatomVisibilityCD {
//        let visibility: VatomVisibilityCD = context.insertObject()
//        guard
//            let _type = descriptor["type"] as? String,
//            let _value = descriptor["value"] as? String
//            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
//        visibility.type = _type
//        visibility.value = _value
//        
//        return visibility
//    }
//    
//}
//
//extension VatomChildPolicyCD: JSONUpdatable {
//    
//    /// Convenience method to update a vatom object with a dictionary.
//    static func update(into context: NSManagedObjectContext, with descriptor: [String: Any]) throws -> VatomChildPolicyCD {
//        let childPolicy: VatomChildPolicyCD = context.insertObject()
//        guard
//            let _count = descriptor["count"] as? Int,
//            let _creationPolicyDescriptor = descriptor["creation_policy"] as? [String: Any],
//            let _templateVariationID = descriptor["template_variation"] as? String
//            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
//        
//        childPolicy.count = _count
//        childPolicy.creationPolicy = try VatomCreationPolicyCD.update(into: context, with: _creationPolicyDescriptor)
//        childPolicy.templateVariationID = _templateVariationID
//        
//        return childPolicy
//    }
//    
//}
//
//extension VatomCreationPolicyCD: JSONUpdatable {
//    
//    static func update(into context: NSManagedObjectContext, with descriptor: [String: Any]) throws -> VatomCreationPolicyCD {
//        
//        let creationPolicy: VatomCreationPolicyCD = context.insertObject()
//        guard
//            let _autoCreate            = descriptor["auto_create"] as? String,
//            let _autoCreateCount       = descriptor["auto_create_count"] as? Int,
//            let _autoCreateCountRandom = descriptor["auto_create_count_random"] as? Bool,
//            let _enforcePolicyCountMax = descriptor["enforce_policy_count_max"] as? Bool,
//            let _enforcePolicyCountMin = descriptor["enforce_policy_count_min"] as? Bool,
//            let _policyCountMax        = descriptor["policy_count_max"] as? Int,
//            let _policyCountMin        = descriptor["policy_count_min"] as? Int
//            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
//        
//        creationPolicy.autoCreate = _autoCreate
//        creationPolicy.autoCreateCount = _autoCreateCount
//        creationPolicy.autoCreateCountRandom = _autoCreateCountRandom
//        creationPolicy.enforcePolicyCountMax = _enforcePolicyCountMax
//        creationPolicy.enforcePolicyCountMin = _enforcePolicyCountMin
//        creationPolicy.policyCountMax = _policyCountMax
//        creationPolicy.policyCountMin = _policyCountMin
//        
//        return creationPolicy
//    }
//    
//}
//
//
//extension VatomCommerceCD: JSONUpdatable {
//
//    static func update(into context: NSManagedObjectContext, with descriptor: [String: Any]) throws -> VatomCommerceCD {
//        let commerce: VatomCommerceCD = context.insertObject()
//        guard
//            let _pricingDescriptor = descriptor["pricing"] as? [String: Any],
//            let _vatomPricing = try? VatomPricingCD.update(into: context, with: _pricingDescriptor)
//            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
//        
//        commerce.pricing = _vatomPricing
//        return commerce
//    }
//    
//}
//
//
//extension VatomPricingCD: JSONUpdatable {
//    
//    static func update(into context: NSManagedObjectContext, with descriptor: [String: Any]) throws -> VatomPricingCD {
//        let pricing: VatomPricingCD = context.insertObject()
//        guard
//            let _pricingType        = descriptor["pricingType"] as? String,
//            let _valueDescriptor    = descriptor["value"] as? [String: Any],
//            let _currency           = _valueDescriptor["currency"] as? String,
//            let _price              = _valueDescriptor["price"] as? String,
//            let _validFrom          = _valueDescriptor["valid_from"] as? String,
//            let _validThrough       = _valueDescriptor["valid_through"] as? String,
//            let _isVatIncluded      = _valueDescriptor["vat_included"] as? Bool
//            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
//        
//        pricing.pricingType = _pricingType
//        pricing.currency = _currency
//        pricing.price = _price
//        pricing.validFrom = _validFrom
//        pricing.validThrough = _validThrough
//        pricing.isVatIncluded = _isVatIncluded
//        return pricing
//    }
//    
//}


extension VatomCD {
    
    public func listCachedChildren() throws -> [VatomCD] {
        
        return [] //FIXME: ...
    
    }

    /// Returns the value for the given keypath (or `nil` if the keypath cannot be parsed).
    public func valueForKeyPath(_ keypath: String) -> JSON? {
        
        return JSON.null //FIXME: ...
        
    }
    
    /// Convert VatomCD to VatomModel.
    ///
    /// This is temporary and allows the bridge to work as-is for now.
    public var structModel: VatomModel {
        
        let rootProps = RootProperties(author: self.author,
                                       rootType: self.rootType,
                                       templateID: self.templateID,
                                       templateVariationID: self.templateVariationID,
                                       publisherFQDN: self.publisherFQDN,
                                       title: self.title,
                                       description: self.description,
                                       category: self.category,
                                       childPolicy: self.childPolicy.map{ $0.structModel },
                                       clonedFrom: self.clonedFrom,
                                       cloningScore: self.cloningScore,
                                       commerce: self.commerce.structModel,
                                       isInContract: self.isInContract,
                                       inContractWith: self.inContractWith,
                                       notifyMessage: self.notifyMessage,
                                       numberDirectClones: self.numberDirectClones,
                                       owner: self.owner,
                                       parentID: self.parentID,
                                       tags: [], //FIXME: ...
                                       transferredBy: self.transferredBy,
                                       visibility: self.visibility.structModel,
                                       isAcquirable: self.isAcquirable,
                                       isRedeemable: self.isRedeemable,
                                       isDisabled: self.isDisabled,
                                       isDropped: self.isDropped,
                                       isTradeable: self.isTradeable,
                                       isTransferable: self.isTransferable,
                                       geoPosition: RootProperties.GeoPosition(type: "Point", coordinates: [self.longitude, self.latitude]),
                                       resources: self.resources.map { $0.structModel })
        
        return VatomModel(id: self.id,
                          version: self.version,
                          whenCreated: self.whenCreated,
                          whenAdded: self.whenAdded,
                          whenModified: self.whenModified,
                          isUnpublished: self.isUnpublished,
                          sync: UInt(self.sync),
                          props: rootProps,
                          private: self.private,
                          eos: self.cryptoEOS,
                          eth: self.cryptoETH,
                          faceModels: self.faces.map { $0.structModel },
                          actionModels: self.actions.map { $0.structModel })
    }
    
}
