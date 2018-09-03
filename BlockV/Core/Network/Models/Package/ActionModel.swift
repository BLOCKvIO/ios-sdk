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

/// This type models a template action.
public struct ActionModel: Equatable {

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

    public struct Properties: Codable, Equatable {
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

extension ActionModel: Decodable {

    /// Initialise from a decoder, e.g. JSONDecoder
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = try container.decode(String.self, forKey: .name)
        let properties = try container.decodeIfPresent(Properties.self, forKey: .properties)
        let meta = try container.decodeIfPresent(MetaModel.self, forKey: .meta)

        let (templateID, actionName) = try ActionModel.splitCompoundName(name)

        self.init(compoundName: name,
                  name: actionName,
                  templateID: templateID,
                  meta: meta,
                  properties: properties)
    }

}

// MARK: - Helpers 

extension ActionModel {

    /// Extract action and template name from the compound name.
    private static func splitCompoundName(_ compoundName: String) throws -> (String, String) {

        // find the marker
        guard let markerRange = compoundName.range(of: "::action::",
                                                   options: .caseInsensitive,
                                                   range: nil,
                                                   locale: nil) else {
            throw  BVError.modelDecoding(reason:
                "Unable to split compound name into template and action names. Compound: \(compoundName)")
        }

        // extract template id
        let templateID = String(compoundName[compoundName.startIndex..<markerRange.lowerBound])

        // extract action name
        let actionName = String(compoundName[markerRange.upperBound..<compoundName.endIndex])

        return (templateID, actionName)
    }

}

// MARK: - Hashable

extension ActionModel: Hashable {

    public var hashValue: Int {
        return compoundName.hashValue
    }

}
