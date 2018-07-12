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

public struct VatomModel: Equatable {

    // Top Level Properties

    // constants
    public let id: String
    public let version: String
    public let whenCreated: Date

    // variables
    public var whenModified: Date
    public var isUnpublished: Bool

    // Second Level (de-nested one level)

    // constants
    public let author: String
    public let rootType: String
    public let templateID: String
    public let templateVariationID: String
    public let publisherFqdn: String

    // variables
    public var category: String
    public var childPolicy: [VatomChildPolicy]
    public var clonedFrom: String
    public var cloningScore: Double
    public var commerce: Commerce
    public var description: String
    public var isInContract: Bool
    public var inContractWith: String
    public var notifyMessage: String
    public var numberDirectClones: Int
    public var owner: String
    public var parentID: String
    public var tags: [String]
    public var title: String
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
    public var privateProperties: JSON? // Private section may contain JSON of any structure.

    enum CodingKeys: String, CodingKey {
        case id
        case version
        case isUnpublished     = "unpublished"
        case whenCreated       = "when_created"
        case whenModified      = "when_modified"
        case properties        = "vAtom::vAtomType"
        case privateProperties = "private"
    }

    enum PropertiesCodingKeys: String, CodingKey {

        case author
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
        case publisherFqdn       = "publisher_fqdn"
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
        public let type: String
        public let value: String
    }

    public struct Commerce: Codable, Equatable {
        public let pricing: VatomPricing
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

// MARK: Codable

extension VatomModel: Decodable {

    public init(from decoder: Decoder) throws {
        let items = try decoder.container(keyedBy: CodingKeys.self)
        id                = try items.decode(String.self, forKey: .id)
        version           = try items.decode(String.self, forKey: .version)
        isUnpublished     = try items.decode(Bool.self, forKey: .isUnpublished)
        whenCreated       = try items.decode(Date.self, forKey: .whenCreated)
        whenModified      = try items.decode(Date.self, forKey: .whenModified)

        privateProperties = try items.decodeIfPresent(JSON.self, forKey: .privateProperties)

        // de-nest properties to top level
        let propertiesContainer = try items.nestedContainer(keyedBy: PropertiesCodingKeys.self, forKey: .properties)
        isAcquirable        = try propertiesContainer.decode(Bool.self, forKey: .isAcquirable)
        author              = try propertiesContainer.decode(String.self, forKey: .author)
        category            = try propertiesContainer.decode(String.self, forKey: .category)
        clonedFrom          = try propertiesContainer.decode(String.self, forKey: .clonedFrom)
        cloningScore        = try propertiesContainer.decode(Double.self, forKey: .cloningScore)
        commerce            = try propertiesContainer.decode(Commerce.self, forKey: .commerce)
        description         = try propertiesContainer.decode(String.self, forKey: .description)
        isDisabled          = try propertiesContainer.decode(Bool.self, forKey: .isDisabled)
        isDropped           = try propertiesContainer.decode(Bool.self, forKey: .isDropped)
        geoPosition         = try propertiesContainer.decode(GeoPosition.self, forKey: .geoPosition)
        isInContract        = try propertiesContainer.decode(Bool.self, forKey: .isInContract)
        inContractWith      = try propertiesContainer.decode(String.self, forKey: .inContractWith)
        notifyMessage       = try propertiesContainer.decode(String.self, forKey: .notifyMessage)
        numberDirectClones  = try propertiesContainer.decode(Int.self, forKey: .numberDirectClones)
        owner               = try propertiesContainer.decode(String.self, forKey: .owner)
        parentID            = try propertiesContainer.decode(String.self, forKey: .parentID)
        publisherFqdn       = try propertiesContainer.decode(String.self, forKey: .publisherFqdn)
        isRedeemable        = try propertiesContainer.decode(Bool.self, forKey: .isRedeemable)
        resources           = try propertiesContainer.decode([Safe<VatomResourceModel>].self,
                                                             forKey: .resources).compactMap { $0.value }
        rootType            = try propertiesContainer.decode(String.self, forKey: .rootType)
        templateID          = try propertiesContainer.decode(String.self, forKey: .templateID)
        templateVariationID = try propertiesContainer.decode(String.self, forKey: .templateVariationID)
        title               = try propertiesContainer.decode(String.self, forKey: .title)
        isTradeable         = try propertiesContainer.decode(Bool.self, forKey: .isTradeable)
        isTransferable      = try propertiesContainer.decode(Bool.self, forKey: .isTransferable)
        transferredBy       = try propertiesContainer.decode(String.self, forKey: .transferredBy)
        visibility          = try propertiesContainer.decode(Visibility.self, forKey: .visibility)

        // potentially absent from container
        tags                = try propertiesContainer.decodeIfPresent([String].self,
                                                                      forKey: .tags) ?? []
        childPolicy         = try propertiesContainer.decodeIfPresent([VatomChildPolicy].self,
                                                                      forKey: .childPolicy) ?? []

    }

}

// MARK: Hashable

extension VatomModel: Hashable {

    /// vAtoms are uniquely identified by their platform identifier.
    public var hashValue: Int {
        return id.hashValue
    }
}

// MARK: - Vatom Pricing

public struct VatomPricing: Equatable {

    public let pricingType: String
    public let currency: String
    public let price: String
    public let validFrom: String
    public let validThrough: String
    public let isVatIncluded: Bool

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
