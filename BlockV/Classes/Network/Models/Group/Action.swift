//
//  Action.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/03/02.
//

import Foundation

//TODO: Define hashable conformance

/// This type models a template action.
///
///
public struct Action {
    
    /// Combination of the template and action name.
    ///
    /// E.g. vatomic.prototyping::v1::vAtom::Combined::Action::Pickup
    let compoundName: String
    
    /// Action name. Also serves as the action's unique identifier.
    ///
    /// E.g. PickUp
    public let name: String
    
    /// Template name
    ///
    /// E.g. vatomic.prototyping::v1::vAtom::Combined
    public let templateID: String
    
    /*
     NB: `meta` and `properties` are only returned in group responses.
     Calls such as GET /user/actions/:template_id do not.
    */
    public let meta: MetaModel?
    public let properties: Properties?

    public struct Properties: Codable {
        public let reactor: String
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case templateName
        case meta
        case properties
    }
    
}

// MARK: - Decodable

extension Action: Decodable {

    /// Initialise from a decoder, e.g. JSONDecoder
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let name = try container.decode(String.self, forKey: .name)
        let properties = try container.decodeIfPresent(Properties.self, forKey: .properties)
        let meta = try container.decodeIfPresent(MetaModel.self, forKey: .meta)
        
        let (templateID, actionName) = try Action.splitCompoundName(name)
        
        self.init(compoundName: name,
                  name: actionName,
                  templateID: templateID,
                  meta: meta,
                  properties: properties)
    }
    
}

// MARK: - Helpers 

extension Action {
    
    /// Extract action and template name from the compound name.
    private static func splitCompoundName(_ compoundName: String) throws -> (String, String) {
        
        // find the marker
        guard let markerRange = compoundName.range(of: "::action::", options: .caseInsensitive, range: nil, locale: nil) else {
            throw  BVError.modelDecoding(reason: "Unable to split compound name into template and action names. Compound: \(compoundName)")
        }
        
        // extract template id
        let templateID = String(compoundName[compoundName.startIndex..<markerRange.lowerBound])
        
        // extract action name
        let actionName = String(compoundName[markerRange.upperBound..<compoundName.endIndex])
        
        return (templateID, actionName)
    }
    
}

// MARK: - Equatable

extension Action: Equatable {}

public func ==(lhs: Action, rhs: Action) -> Bool {
    return lhs.compoundName == rhs.compoundName &&
    lhs.name == rhs.name &&
    lhs.templateID == rhs.templateID &&
    lhs.meta == rhs.meta &&
    lhs.properties == rhs.properties
}

extension Action.Properties: Equatable {}

public func ==(lhs: Action.Properties, rhs: Action.Properties) -> Bool {
    return lhs.reactor == rhs.reactor
}
