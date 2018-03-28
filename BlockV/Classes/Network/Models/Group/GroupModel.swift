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
public struct GroupModel: Decodable {
    
    public var vatoms: [Vatom]
    public var faces: [Face]
    public var actions: [Action]
    public var count: Int?
    
    /// These coding keys accomadate both the inventory and discover calls.
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
         The arrays of vatoms, faces, and actions are be decded 'safely'. In other words,
         encountering a failure when decoding a an element will result in that element
         not being included in the parsed arrays.
         */
        
        /*
         Below is a workaround to accomadate the inventory and discover calls.
         */
        
        if let vatoms = try container.decodeIfPresent([Safe<Vatom>].self, forKey: .vatoms) {
            self.vatoms = vatoms.flatMap { $0.value }
        } else if let vatoms = try container.decodeIfPresent([Safe<Vatom>].self, forKey: .results) {
            self.vatoms = vatoms.flatMap { $0.value }
        } else {
            self.vatoms = []
        }
        
        /*
         Ideally, is should just be this.
         
         self.vatoms = try container
         .decode([Safe<Vatom>].self, forKey: .vatoms)
         .flatMap { $0.value }
         
         */
        
        self.faces = try container
            .decode([Safe<Face>].self, forKey: .faces)
            .flatMap { $0.value }
        self.actions = try container
            .decode([Safe<Action>].self, forKey: .actions)
            .flatMap { $0.value }
        self.count = try container.decodeIfPresent(Int.self, forKey: .count)
    }
    
}

// MARK: Equatable

extension GroupModel: Equatable {}

public func ==(lhs: GroupModel, rhs: GroupModel) -> Bool {
    return lhs.faces == rhs.faces &&
        lhs.actions == rhs.actions &&
        lhs.vatoms == rhs.vatoms &&
        lhs.count == rhs.count
}
