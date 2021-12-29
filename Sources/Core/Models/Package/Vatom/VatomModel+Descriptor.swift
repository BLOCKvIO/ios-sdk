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

import Foundation
import GenericJSON

//swiftlint:disable identifier_name

protocol Descriptable {
    init(from descriptor: [String: Any]) throws
}

extension VatomModel: Descriptable {

    init(from descriptor: [String: Any]) throws {

        guard
            let _id             = descriptor["id"] as? String,
            let _version        = descriptor["version"] as? String,
            let _whenCreated    = descriptor["when_created"] as? String,
            let _whenModified   = descriptor["when_modified"] as? String,
            let _whenAdded      = descriptor["when_added"] as? String,
            let _sync           = descriptor["sync"] as? UInt,
            let _private        = descriptor["private"] as? [String: Any],
            let _rootDescriptor = descriptor["vAtom::vAtomType"] as? [String: Any]

            else { throw BVError.modelDecoding(reason: "Model decoding failed: \(type(of: self))") }

        self.id = _id
        self.version = _version
        self.whenCreated = DateFormatter.blockvDateFormatter.date(from: _whenCreated)! //FIXME: force
        self.whenModified = DateFormatter.blockvDateFormatter.date(from: _whenModified)! //FIXME: force
        self.whenAdded = DateFormatter.blockvDateFormatter.date(from: _whenAdded)! //FIXME: force
        self.sync = _sync
        self.private = try? JSON.init(_private)
        self.props = try RootProperties(from: _rootDescriptor)

        self.faceModels = []
        self.actionModels = []

        // Store ETH section
        if let _eth = descriptor["eth"] as? [String:Any] {
            self.eth = try? JSON(_eth)
        }
        
        // Store EOS section
        if let _eos = descriptor["eos"] as? [String:Any] {
            self.eos = try? JSON(_eos)
        }

        self.isUnpublished = (descriptor["unpublished"] as? Bool) ?? false

    }

}

extension RootProperties: Descriptable {

    init(from descriptor: [String: Any]) throws {

        guard
            let _author                 = descriptor["author"] as? String,
            let _rootType               = descriptor["root_type"] as? String,
            let _templateID             = descriptor["template"] as? String,
            let _templateVariationID    = descriptor["template_variation"] as? String,
            let _publisherFQDN          = descriptor["publisher_fqdn"] as? String,
            let _title                  = descriptor["title"] as? String,
            let _description            = descriptor["description"] as? String,

            let _category               = descriptor["category"] as? String,
            let _clonedFrom             = descriptor["cloned_from"] as? String,
            let _cloningScore           = descriptor["cloning_score"] as? Double,
            let _commerceDescriptor     = descriptor["commerce"] as? [String: Any],
            let _isInContract           = descriptor["in_contract"] as? Bool,
            let _inContractWith         = descriptor["in_contract_with"] as? String,
            let _notifyMessage          = descriptor["notify_msg"] as? String,
            let _numberDirectClones     = descriptor["num_direct_clones"] as? Int,
            let _owner                  = descriptor["owner"] as? String,
            let _parentID               = descriptor["parent_id"] as? String,
            let _transferredBy          = descriptor["transferred_by"] as? String,
            let _visibilityDescriptor   = descriptor["visibility"] as? [String: Any],

            let _isAcquirable           = descriptor["acquirable"] as? Bool,
            let _isRedeemable           = descriptor["redeemable"] as? Bool,
            let _isDisabled             = descriptor["disabled"] as? Bool,
            let _isDropped              = descriptor["dropped"] as? Bool,
            let _isTradeable            = descriptor["tradeable"] as? Bool,
            let _isTransferable         = descriptor["transferable"] as? Bool,

            let _geoPositionDescriptor  = descriptor["geo_pos"] as? [String: Any],
            let _resourceDescriptor     = descriptor["resources"] as? [[String: Any]]

            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }

        // decode if present
        let _activateAction         = descriptor["activate_action"] as? String ?? ""
        let _childPolicyDescriptor  = descriptor["child_policy"] as? [[String: Any]] ?? []
        let _tags                   = descriptor["tags"] as? [String] ?? []

        self.author = _author
        self.rootType = _rootType
        self.templateID = _templateID
        self.templateVariationID = _templateVariationID
        self.publisherFQDN = _publisherFQDN
        self.title = _title
        self.description = _description

        self.activateAction = _activateAction
        self.category = _category
        self.childPolicy = _childPolicyDescriptor.compactMap { try? VatomChildPolicy(from: $0) }
        self.clonedFrom = _clonedFrom
        self.cloningScore = _cloningScore
        self.commerce = try Commerce(from: _commerceDescriptor)
        self.isInContract = _isInContract
        self.inContractWith = _inContractWith
        self.notifyMessage = _notifyMessage
        self.numberDirectClones = _numberDirectClones
        self.owner = _owner
        self.parentID = _parentID
        self.tags = _tags
        self.transferredBy = _transferredBy
        self.visibility = try Visibility(from: _visibilityDescriptor)

        self.isAcquirable = _isAcquirable
        self.isRedeemable = _isRedeemable
        self.isDisabled = _isDisabled
        self.isDropped = _isDropped
        self.isTradeable = _isTradeable
        self.isTransferable = _isTransferable

        self.geoPosition = try GeoPosition(from: _geoPositionDescriptor)
        self.resources = _resourceDescriptor.compactMap { try? VatomResourceModel(from: $0) }

    }

}

extension RootProperties.Visibility: Descriptable {

    init(from descriptor: [String: Any]) throws {
        guard
            let _type = descriptor["type"] as? String,
            let _value = descriptor["value"] as? String
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }

        self.type = _type
        self.value = _value

    }

}

extension RootProperties.Commerce: Descriptable {

    init(from descriptor: [String: Any]) throws {
        guard
            let _pricingDescriptor = descriptor["pricing"] as? [String: Any],
            let _vatomPricing = try? VatomPricing(from: _pricingDescriptor)
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }

        self.pricing = _vatomPricing

    }

}

extension VatomPricing: Descriptable {

    init(from descriptor: [String: Any]) throws {
        guard
            let _pricingType        = descriptor["pricingType"] as? String,
            let _valueDescriptor    = descriptor["value"] as? [String: Any],
            let _currency           = _valueDescriptor["currency"] as? String,
            let _price              = _valueDescriptor["price"] as? String,
            let _validFrom          = _valueDescriptor["valid_from"] as? String,
            let _validThrough       = _valueDescriptor["valid_through"] as? String,
            let _isVatIncluded      = _valueDescriptor["vat_included"] as? Bool
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }

        self.pricingType = _pricingType
        self.currency = _currency
        self.price = _price
        self.validFrom = _validFrom
        self.validThrough = _validThrough
        self.isVatIncluded = _isVatIncluded
    }

}

extension VatomChildPolicy: Descriptable {

    init(from descriptor: [String: Any]) throws {

        guard
            let _count = descriptor["count"] as? Int,
            let _creationPolicyDescriptor = descriptor["creation_policy"] as? [String: Any],
            let _templateVariationID = descriptor["template_variation"] as? String
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }

        self.count = _count
        self.creationPolicy = try CreationPolicy(from: _creationPolicyDescriptor)
        self.templateVariationID = _templateVariationID
    }

}

extension VatomChildPolicy.CreationPolicy: Descriptable {

    init(from descriptor: [String: Any]) throws {
        guard
        let _autoCreate            = descriptor["auto_create"] as? String,
        let _autoCreateCount       = descriptor["auto_create_count"] as? Int,
        let _autoCreateCountRandom = descriptor["auto_create_count_random"] as? Bool,
        let _enforcePolicyCountMax = descriptor["enforce_policy_count_max"] as? Bool,
        let _enforcePolicyCountMin = descriptor["enforce_policy_count_min"] as? Bool,
        let _policyCountMax        = descriptor["policy_count_max"] as? Int,
        let _policyCountMin        = descriptor["policy_count_min"] as? Int
        else { throw BVError.modelDecoding(reason: "Model decoding failed.") }

        self.autoCreate = _autoCreate
        self.autoCreateCount = _autoCreateCount
        self.autoCreateCountRandom = _autoCreateCountRandom
        self.enforcePolicyCountMax = _enforcePolicyCountMax
        self.enforcePolicyCountMin = _enforcePolicyCountMin
        self.policyCountMax = _policyCountMax
        self.policyCountMin = _policyCountMin

    }

}

extension RootProperties.GeoPosition: Descriptable {

    init(from descriptor: [String: Any]) throws {
        guard
            let _type = descriptor["type"] as? String,
            let _coordinates = descriptor["coordinates"] as? [Double]
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }

        self.type = _type
        self.coordinates = _coordinates
    }

}

extension VatomResourceModel: Descriptable {

    init(from descriptor: [String: Any]) throws {
        guard
            let _name = descriptor["name"] as? String,
            let _type = descriptor["resourceType"] as? String,
            let _value = (descriptor["value"] as? [String: Any])?["value"] as? String,
            let _url = URL(string: _value)
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }

        self.name = _name
        self.type = _type
        self.url = _url

     }

}
