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

/// A struct that holds **unpackaged** vAtoms.
///
/// - Array of unpackaged vAtoms
/// - Array of faces for each of the present templates.
///   - Technically, a consolidated array of all the faces linked to the parent templates of the present vAtoms.
/// - Array of actions for each of the present templates.
///   - Technically, a consolidated array of all the actions linked to the parent templates of the present vAtoms.
public struct UnpackedModel: Decodable, Equatable {

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

    /// Applies a transformation on an unpacked vatom model to produce a packed vatom models.
    ///
    /// The resulting vatoms have their template's face and action models directly attached.
    ///
    /// - note:
    /// Actions and Faces are associated at the template level. The BLOCKv API returns vAtoms, Action, and Faces as
    /// three separate arrays (i.e. unpacked). This methods 'packages' the actions and faces onto associated vatoms.
    func package() -> [VatomModel] {

        // dictionary keyed by template id, mapping a templateId to face models
        let facesByTemplate = Dictionary(grouping: self.faces, by: { face in face.templateID })
        // dictionary keyed by template id, mapping a templateId to action models
        let actionsByTemplate = Dictionary(grouping: self.actions, by: { action in action.templateID })

        // associate actions and faces with each vatom
        var packedVatoms = self.vatoms
        for (index, vatom) in packedVatoms.enumerated() {
            packedVatoms[index].faceModels = facesByTemplate[vatom.props.templateID] ?? []
            packedVatoms[index].actionModels = actionsByTemplate[vatom.props.templateID] ?? []
        }

        // return the packed vatoms
        return packedVatoms

    }

}
