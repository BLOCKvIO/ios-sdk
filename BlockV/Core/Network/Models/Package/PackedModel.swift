////
////  BlockV AG. Copyright (c) 2018, all rights reserved.
////
////  Licensed under the BlockV SDK License (the "License"); you may not use this file or
////  the BlockV SDK except in compliance with the License accompanying it. Unless
////  required by applicable law or agreed to in writing, the BlockV SDK distributed under
////  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
////  ANY KIND, either express or implied. See the License for the specific language
////  governing permissions and limitations under the License.
////

import Foundation

/// The process of 'packing' a vAtom means associating the template's actions and faces with the vAtom directly.
public struct PackedModel: Decodable, Equatable {

    /// Array of *packed* vAtom models.
    ///
    /// A packaged vAtom has its parent template's face and action models associated with it. This makes working with
    /// a vAtom model easier.
    public var vatoms: [VatomModel]
    public var count: Int

    /// Initialize with an unpacked model.
    init(unpackedModel: UnpackedModel) {
        self.vatoms = unpackedModel.vatoms
        self.count = vatoms.count

        // TODO: Package the actions and faces
    }

    /// Initialize with packed vAtoms.
    ///
    /// - important: The vAtoms must have been packaged by this point.
    private init(vatoms: [VatomModel]) {
        self.vatoms = vatoms
        self.count = vatoms.count
    }

    /// Applies a transformation on an unpacked vatom model to produce a packed vatom model.
    ///
    /// The resulting PackedModel has an array of vatoms which have their template's face and action models directly
    /// attached.
    ///
    /// - note:
    /// Actions and Faces are associated at the template level. The BLOCKv API returns vAtoms, Action, and Faces as
    /// three separate arrays (i.e. unpacked). This methods 'packages' the actions and faces onto associated vatoms.
    static func transform(_ unpackedModel: UnpackedModel) -> PackedModel {

        // dictionary keyed by template id, mapping a templateId to face models
        let facesByTemplate = Dictionary(grouping: unpackedModel.faces, by: { face in face.templateID })
        // dictionary keyed by template id, mapping a templateId to action models
        let actionsByTemplate = Dictionary(grouping: unpackedModel.actions, by: { action in action.templateID })

        // associate actions and faces with each vatom
        var packedVatoms = unpackedModel.vatoms
        for (index, vatom) in packedVatoms.enumerated() {
            packedVatoms[index].faceModels = facesByTemplate[vatom.templateID] ?? []
            packedVatoms[index].actionModels = actionsByTemplate[vatom.templateID] ?? []
        }

        return PackedModel(vatoms: packedVatoms)

    }

}
