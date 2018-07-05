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

/// A simple struct that holds the three components necessary to interaction with vAtoms.
///
/// These are:
/// 1. Array of vAtoms
/// 2. Array of all the faces associated with the vAtoms.
///   Technically, an array of all the faces linked to the parent templates of the vAtoms in the vAtoms array.
/// 3. Array of all the actions associated with the vAtoms.
///   Technically, an array of all the actions linked to the parent templates of the vAtoms in the vAtoms array.
public struct PackModel: Decodable, Equatable {

    public var vatoms: [VatomModel]
    public var faces: [FaceModel]
    public var actions: [ActionModel]
    public var count: Int?

    /// These coding keys accomadate both the inventory and discover calls.
    ///
    /// TODO: There may be a better way of handling this. Investigate.
    enum CodingKeys: String, CodingKey {
        case results // discover only
        case vatoms
        case faces
        case actions
        case count
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        /*
         Below is a workaround to accomadate both the inventory and discover calls' json keys.
         This has a pitfall in that the keys 'vatoms' and 'results' may never both appear in
         either payload.
         
         Ideally, should just be:
         
         self.vatoms = try container
         .decode([Safe<VatomModel>].self, forKey: .vatoms)
         .compactMap { $0.value }
         
         */

        if let vatoms = try container.decodeIfPresent([Safe<VatomModel>].self, forKey: .vatoms) {
            self.vatoms = vatoms.compactMap { $0.value }
        } else if let vatoms = try container.decodeIfPresent([Safe<VatomModel>].self, forKey: .results) {
            self.vatoms = vatoms.compactMap { $0.value }
        } else {
            self.vatoms = []
        }

        self.faces = try container
            .decode([Safe<FaceModel>].self, forKey: .faces)
            .compactMap { $0.value }
        self.actions = try container
            .decode([Safe<ActionModel>].self, forKey: .actions)
            .compactMap { $0.value }
        self.count = try container.decodeIfPresent(Int.self, forKey: .count)

        /*
         NOTE: The arrays of vatoms, faces, and actions are be decded 'safely'. In other words,
         encountering a failure when decoding an element will result in only that element not being
         included in the decoded array. This is opposed to the default behaviour of `decode` for
         collections where the decoding failure of a single element throws and no elements are
         added.
         */

    }

}
