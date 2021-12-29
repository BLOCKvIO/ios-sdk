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

public struct VatomModel: Equatable {

    // MARK: - Properties

    // constants
    public let id: String
    public let version: String
    public let whenCreated: Date
    public let whenAdded: Date
    // variables
    public var whenModified: Date
    public var isUnpublished: Bool
    public var sync: UInt

    /// Template properties.
    ///
    /// - note: Some template properties are mutable by reactors.
    public var props: RootProperties
    /// Private properties.
    ///
    /// - note: Private properties are mutable by reactors.
    public var `private`: JSON?

    // crypto
    public var eos: JSON?
    public var eth: JSON?

    /// Array of face models associated with this vAtom's template.
    ///
    /// - note: Subject to change over the life of the vAtom.
    public var faceModels: [FaceModel]
    /// Array of action models associated with this vAtom's template.
    ///
    /// - note: Subject to change over the life of the vAtom.
    public var actionModels: [ActionModel]

    enum CodingKeys: String, CodingKey {
        case id
        case version
        case isUnpublished     = "unpublished"
        case whenCreated       = "when_created"
        case whenModified      = "when_modified"
        case whenAdded         = "when_added"
        case props             = "vAtom::vAtomType"
        case `private`         = "private"
        case faceModels        = "faces"
        case actionModels      = "actions"
        case eos               = "eos"
        case eth               = "eth"
        case sync              = "sync"
    }

}

// MARK: Codable
extension VatomModel: Codable {

    public init(from decoder: Decoder) throws {
        let items = try decoder.container(keyedBy: CodingKeys.self)
        id                = try items.decode(String.self, forKey: .id)
        version           = try items.decode(String.self, forKey: .version)
        whenCreated       = try items.decode(Date.self, forKey: .whenCreated)
        whenModified      = try items.decode(Date.self, forKey: .whenModified)
        whenAdded         = try items.decode(Date.self, forKey: .whenAdded)
        sync              = try items.decode(UInt.self, forKey: .sync)
        props             = try items.decode(RootProperties.self, forKey: .props)

        isUnpublished     = try items.decodeIfPresent(Bool.self, forKey: .isUnpublished) ?? false
        `private`         = try items.decodeIfPresent(JSON.self, forKey: .private)
        eos               = try items.decodeIfPresent(JSON.self, forKey: .eos)
        eth               = try items.decodeIfPresent(JSON.self, forKey: .eth)
        faceModels        = try items.decodeIfPresent([FaceModel].self, forKey: .faceModels) ?? []
        actionModels      = try items.decodeIfPresent([ActionModel].self, forKey: .actionModels) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(version, forKey: .version)
        try container.encode(isUnpublished, forKey: .isUnpublished)
        try container.encode(whenCreated, forKey: .whenCreated)
        try container.encode(whenModified, forKey: .whenModified)
        try container.encode(whenAdded, forKey: .whenAdded)
        try container.encode(props, forKey: .props)
        try container.encode(`private`, forKey: .`private`)
        try container.encode(eos, forKey: .eos)
        try container.encode(eth, forKey: .eth)
        try container.encode(faceModels, forKey: .faceModels)
        try container.encode(actionModels, forKey: .actionModels)
    }

}

// MARK: Hashable
extension VatomModel: Hashable {

    /// vAtoms are uniquely identified by their platform identifier.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

// MARK: - Vatom Root Properties

public struct RootProperties: Equatable {

    // constants
    public let author: String
    public let rootType: String
    public let templateID: String
    public let templateVariationID: String
    public let publisherFQDN: String
    public let title: String
    public let description: String

    // variables
    public var activateAction: String
    public var category: String
    public var childPolicy: [VatomChildPolicy]
    public var clonedFrom: String
    public var cloningScore: Double
    public var commerce: Commerce
    public var isInContract: Bool
    public var inContractWith: String
    public var notifyMessage: String
    public var numberDirectClones: Int
    public var owner: String
    public var parentID: String
    public var tags: [String]
    public var transferredBy: String
    public var visibility: Visibility

    public var isAcquirable: Bool
    public var isRedeemable: Bool
    public var isDisabled: Bool
    public var isDropped: Bool
    public var isTradeable: Bool
    public var isTransferable: Bool

    public var geoPosition: GeoPosition
    public var resources: [VatomResourceModel] // `var` only to allow for resource encoding

    enum CodingKeys: String, CodingKey {

        case author
        case activateAction      = "activate_action"
        case category
        case childPolicy         = "child_policy"
        case clonedFrom          = "cloned_from"
        case cloningScore        = "cloning_score"
        case commerce
        case description
        case geoPosition         = "geo_pos"
        case isInContract        = "in_contract"
        case inContractWith      = "in_contract_with"
        case notifyMessage       = "notify_msg"
        case numberDirectClones  = "num_direct_clones"
        case owner
        case parentID            = "parent_id"
        case publisherFQDN       = "publisher_fqdn"
        case resources
        case rootType            = "root_type"
        case tags
        case templateID          = "template"
        case templateVariationID = "template_variation"
        case title

        case transferredBy       = "transferred_by"
        case visibility

        case isAcquirable        = "acquirable"
        case isRedeemable        = "redeemable"
        case isDisabled          = "disabled"
        case isDropped           = "dropped"
        case isTradeable         = "tradeable"
        case isTransferable      = "transferable"

    }

    public struct Visibility: Codable, Equatable {
        public var type: String
        public var value: String
    }

    public struct Commerce: Codable, Equatable {
        public var pricing: VatomPricing
    }

    //TODO: Updgrade to full GeoJSON support.
    /// The geographic position of the vAtom.
    ///
    /// - SeeAlso:
    /// [GeoJSON](https://tools.ietf.org/html/rfc7946)
    public struct GeoPosition: Codable, Equatable {
        /// GeoJSON type. vAtoms are alwyas of type 'Point'
        public var type: String
        /// Coordinates of the vAtom
        /// Format: `[lon, lat]`
        public var coordinates: [Double]
    }

}

//TODO: Add Encodable conformance too.
extension RootProperties: Codable {

    public init(from decoder: Decoder) throws {
        let items = try decoder.container(keyedBy: CodingKeys.self)
        isAcquirable        = try items.decode(Bool.self, forKey: .isAcquirable)
        activateAction      = try items.decode(String.self, forKey: .activateAction)
        author              = try items.decode(String.self, forKey: .author)
        category            = try items.decode(String.self, forKey: .category)
        clonedFrom          = try items.decode(String.self, forKey: .clonedFrom)
        cloningScore        = try items.decode(Double.self, forKey: .cloningScore)
        commerce            = try items.decode(Commerce.self, forKey: .commerce)
        description         = try items.decode(String.self, forKey: .description)
        isDisabled          = try items.decode(Bool.self, forKey: .isDisabled)
        isDropped           = try items.decode(Bool.self, forKey: .isDropped)
        geoPosition         = try items.decode(GeoPosition.self, forKey: .geoPosition)
        isInContract        = try items.decode(Bool.self, forKey: .isInContract)
        inContractWith      = try items.decode(String.self, forKey: .inContractWith)
        notifyMessage       = try items.decode(String.self, forKey: .notifyMessage)
        numberDirectClones  = try items.decode(Int.self, forKey: .numberDirectClones)
        owner               = try items.decode(String.self, forKey: .owner)
        parentID            = try items.decode(String.self, forKey: .parentID)
        publisherFQDN       = try items.decode(String.self, forKey: .publisherFQDN)
        isRedeemable        = try items.decode(Bool.self, forKey: .isRedeemable)
        resources           = try items.decode([Safe<VatomResourceModel>].self,
                                                             forKey: .resources).compactMap { $0.value }
        rootType            = try items.decode(String.self, forKey: .rootType)
        templateID          = try items.decode(String.self, forKey: .templateID)
        templateVariationID = try items.decode(String.self, forKey: .templateVariationID)
        title               = try items.decode(String.self, forKey: .title)
        isTradeable         = try items.decode(Bool.self, forKey: .isTradeable)
        isTransferable      = try items.decode(Bool.self, forKey: .isTransferable)
        transferredBy       = try items.decode(String.self, forKey: .transferredBy)
        visibility          = try items.decode(Visibility.self, forKey: .visibility)

        // keys are potentially absent from container
        tags                = try items.decodeIfPresent([String].self, forKey: .tags) ?? []
        childPolicy         = try items.decodeIfPresent([VatomChildPolicy].self, forKey: .childPolicy) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isAcquirable, forKey: .isAcquirable)
        try container.encode(activateAction, forKey: .activateAction)
        try container.encode(author, forKey: .author)
        try container.encode(category, forKey: .category)
        try container.encode(clonedFrom, forKey: .clonedFrom)
        try container.encode(cloningScore, forKey: .cloningScore)
        try container.encode(commerce, forKey: .commerce)
        try container.encode(description, forKey: .description)
        try container.encode(isDisabled, forKey: .isDisabled)
        try container.encode(isDropped, forKey: .isDropped)
        try container.encode(geoPosition, forKey: .geoPosition)
        try container.encode(isInContract, forKey: .isInContract)
        try container.encode(inContractWith, forKey: .inContractWith)
        try container.encode(notifyMessage, forKey: .notifyMessage)
        try container.encode(numberDirectClones, forKey: .numberDirectClones)
        try container.encode(owner, forKey: .owner)
        try container.encode(parentID, forKey: .parentID)
        try container.encode(publisherFQDN, forKey: .publisherFQDN)
        try container.encode(isRedeemable, forKey: .isRedeemable)
        try container.encode(resources, forKey: .resources)

        try container.encode(rootType, forKey: .rootType)
        try container.encode(templateID, forKey: .templateID)
        try container.encode(templateVariationID, forKey: .templateVariationID)
        try container.encode(title, forKey: .title)
        try container.encode(isTradeable, forKey: .isTradeable)
        try container.encode(isTransferable, forKey: .isTransferable)
        try container.encode(transferredBy, forKey: .transferredBy)
        try container.encode(visibility, forKey: .visibility)

        try container.encode(tags, forKey: .tags)
        try container.encode(childPolicy, forKey: .childPolicy)
    }

}

// MARK: - Vatom Pricing
public struct VatomPricing: Equatable {

    public var pricingType: String
    public var currency: String
    public var price: String
    public var validFrom: String
    public var validThrough: String
    public var isVatIncluded: Bool

    enum CodingKeys: String, CodingKey {
        case pricingType
        case value
    }

    enum ValuesCodingKeys: String, CodingKey {
        case currency
        case price
        case validFrom     = "valid_from"
        case validThrough  = "valid_through"
        case isVatIncluded = "vat_included"
    }
}

// MARK: Codable
extension VatomPricing: Codable {

    public init(from decoder: Decoder) throws {
        let items = try decoder.container(keyedBy: CodingKeys.self)
        pricingType = try items.decode(String.self, forKey: .pricingType)

        // de-nest values to top level
        let valuesContainer = try items.nestedContainer(keyedBy: ValuesCodingKeys.self, forKey: .value)
        currency      = try valuesContainer.decode(String.self, forKey: .currency)
        price         = try valuesContainer.decode(String.self, forKey: .price)
        validFrom     = try valuesContainer.decode(String.self, forKey: .validFrom)
        validThrough  = try valuesContainer.decode(String.self, forKey: .validThrough)
        isVatIncluded = try valuesContainer.decode(Bool.self, forKey: .isVatIncluded)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pricingType, forKey: .pricingType)

        // nest values one level
        var valueContainer = container.nestedContainer(keyedBy: ValuesCodingKeys.self, forKey: .value)
        try valueContainer.encode(price, forKey: .price)
        try valueContainer.encode(validFrom, forKey: .validFrom)
        try valueContainer.encode(validThrough, forKey: .validThrough)
        try valueContainer.encode(isVatIncluded, forKey: .isVatIncluded)
    }

}

// MARK: - Vatom Child Policy

public struct VatomChildPolicy: Codable, Equatable {
    public let count: Int
    public let creationPolicy: CreationPolicy
    public let templateVariationID: String

    enum CodingKeys: String, CodingKey {
        case count
        case creationPolicy = "creation_policy"
        case templateVariationID = "template_variation"
    }

    public struct CreationPolicy: Codable, Equatable {
        public let autoCreate: String
        public let autoCreateCount: Int
        public let autoCreateCountRandom: Bool
        public let enforcePolicyCountMax: Bool
        public let enforcePolicyCountMin: Bool
        public let policyCountMax: Int
        public let policyCountMin: Int

        enum CodingKeys: String, CodingKey {
            case autoCreate            = "auto_create"
            case autoCreateCount       = "auto_create_count"
            case autoCreateCountRandom = "auto_create_count_random"
            case enforcePolicyCountMax = "enforce_policy_count_max"
            case enforcePolicyCountMin = "enforce_policy_count_min"
            case policyCountMax        = "policy_count_max"
            case policyCountMin        = "policy_count_min"
        }
    }

}

extension VatomModel: CustomDebugStringConvertible {

    public var debugDescription: String {
        return """
        ID: \(self.id)
        Template ID: \(self.props.templateID)
        Template Var ID: \(self.props.templateVariationID)
        Publisher FQDN: \(self.props.publisherFQDN)
        Title: \(self.props.title)
        Description: \(self.props.description)
        """
    }

}
