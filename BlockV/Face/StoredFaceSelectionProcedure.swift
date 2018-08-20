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

// MARK: - Typealias

/// Closure used during face model selection.
///
/// A Face Selection Procedure (FSP) is an algorithm used to select the 'best' face model from the (potentially) many
/// faces associated with the vatom's template. An FSP gives Viewers the control over the selection procedure.
///
/// Available inputs:
/// - vAtom to be displayed.
/// - Actions associated with the vAtom's template.
/// - Face modeles associated with the vAtom's template.
/// - Supported display URLs. This is the set of display urls (i.e. unique identifiers of the install native faces).
///
/// - Parameters:
///   - vatomPack: vAtom pack from which the best face should be selected.
///   - displayURLs: Set of displayURLs of supported native faces.
typealias FaceSelectionProcedure = (_ vatomPack: VatomPackModel, _ displayURLs: Set<String>)
    -> FaceModel?

/// Models the face selection procedures (FSP)s. This is a set of pre-built face selection procedures offered by the SDK
/// to meet common use cases.
///
/// It important to think of the cases simply as unique identifiers of stored face selection procedures.
/// Cases loosely map to the server's 'view_mode' simply because the 'view_mode' is generally the predominant selection
/// criteria.
public enum StoredProcedure: String {

    /// Selects based on 'icon' view mode.
    case icon
    /// Selects based on 'activated' view mode.
    case activated
    /// Selects based on 'fullscreen' view mode.
    case fullscreen
    /// Selects based on 'card' view mode.
    case card
    /// Selects based on 'background' view mode.
    case background

    //TODO: The generic viewer will likely specify it's own stored procedures. This means the whole fallback concept
    // should be removed. Rather, the generic viewer should specify its own procedures with its own fallbacks since this
    // is not something the sdk should be offering as a 'common' solution.

    /// A fallback allows one procedure to fallback on antoher in the event the first procedure fails to select a
    /// face model.
    var fallback: StoredProcedure? {
        switch self {
        case .icon:         return nil
        case .activated:    return .icon
        case .fullscreen:   return .icon
        case .card:         return .fullscreen
        case .background:   return nil
        }
    }

    /// Returns the selection procedure for this case.
    var selectionProcedure: FaceSelectionProcedure {
        switch self {
        case .icon:         return StoredProcedureBuilder.iconProcedure
        case .activated:    return StoredProcedureBuilder.activatedProcedure
        case .fullscreen:   return StoredProcedureBuilder.fullscreenProcedure
        case .card:         return StoredProcedureBuilder.cardProcedure
        case .background:   return StoredProcedureBuilder.backgroundProcedure
        }
    }

    // MARK: - Face selection

    /// Selects the 'best' face using this procedure's stored Face Selection Procedure (FSP).
    ///
    /// - Parameters:
    ///   - vatom: The vAtom to be displayed.
    ///   - actions: The action models associated with the vAtom's template.
    ///   - faces: The face models assocated with the vAtom's template.
    ///   - useFallback: Determines whether the fallback procedure should be used. If `true` the fallback is used,
    ///   `false` otherwise.
    /// - Returns: The selected face model, or `nil` if no face model is selected.
    func selectBestFace(vatomPack: VatomPackModel, displayURLs: Set<String>, useFallback: Bool = true)
        -> FaceModel? {
        // execute this procedure, use fallback if necessary
        return self.selectionProcedure(vatomPack, displayURLs) ??
            self.fallback?.selectionProcedure(vatomPack, displayURLs)
    }

    // MARK: Constraints

    /// Constraints associated with this embedded procedure.
    ///
    /// Returns the constrains for this embedded procedure.
    var constraints: SelectionConstraints {
        return SelectionConstraints(viewMode: self.rawValue)
    }

    /// Constraints associated with this embedded procedure.
    ///
    /// These constraints are used as the selection criteria when choosing the best face for this procedure.
    struct SelectionConstraints {
        /// The view_mode of the face.
        let viewMode: String
        // let quality: String // e.g. of futher constraints
    }

}

///
private struct StoredProcedureBuilder {

    // MARK: - Stored Face Selection Procedure (FSP)

    static let iconProcedure: FaceSelectionProcedure = { (vatomPack, displayURLs) in
        StoredProcedureBuilder.defaultSelectionProcedure(vatomPack.faces, displayURLs,
                                                         StoredProcedure.icon.constraints)
    }

    static let activatedProcedure: FaceSelectionProcedure = { (vatomPack, displayURLs)  in
        StoredProcedureBuilder.defaultSelectionProcedure(vatomPack.faces, displayURLs,
                                                         StoredProcedure.activated.constraints)
    }

    static let fullscreenProcedure: FaceSelectionProcedure = { (vatomPack, displayURLs)  in
        StoredProcedureBuilder.defaultSelectionProcedure(vatomPack.faces, displayURLs,
                                                         StoredProcedure.fullscreen.constraints)
    }

    static let cardProcedure: FaceSelectionProcedure = { (vatomPack, displayURLs)  in
        StoredProcedureBuilder.defaultSelectionProcedure(vatomPack.faces, displayURLs,
                                                         StoredProcedure.card.constraints)
    }

    static let backgroundProcedure: FaceSelectionProcedure = { (vatomPack, displayURLs) in
        StoredProcedureBuilder.defaultSelectionProcedure(vatomPack.faces, displayURLs,
                                                         StoredProcedure.background.constraints)
    }

    // MARK: - Stored Procedure

    /// Stored procedures only take in the face models and a set of constraints.
    ///
    /// A face selection procedure takes, as input, an array of face models and a set of face constraints. As output,
    /// it return a face model which satisfies all supplied contraints, or `nil` if no satisfactory face was found.
    ///
    /// - Parameters:
    ///   - faceModels: Array of face models to be used by the selection procedure.
    ///   - constraints: Struct holding face contraints to be used by the selection procedure.
    typealias StoredFaceSelectionProcedure = (_ faceModels: [FaceModel],
        _ displayURLs: Set<String>,
        _ constraints: StoredProcedure.SelectionConstraints)
        -> FaceModel?

    /// Default selection procedure.
    ///
    /// This closure defines a procedure that is common to most stored procedures. Therefore, it makes
    /// sense to the logic in a central place.
    static let defaultSelectionProcedure: StoredFaceSelectionProcedure = { (faceModels, displayURLs, constraints) in

        var bestFace: FaceModel?
        var bestRank = 0

        for face in faceModels {

            var rank = -1

            // ensure 'view mode' is supported
            if face.properties.constraints.viewMode != constraints.viewMode {
                rank = -1
                continue
            }

            // rank 'ios' faces over 'generic'
            if face.properties.constraints.platform == "ios" {
                rank += 2
            } else if face.properties.constraints.platform == "generic" {
                rank += 1
            } else {
                rank = 1
                continue
            }

            // rank 'native' over 'web'
            if face.isNative {
                // enusrue the native face is supported (i.e. the face code is installed)
                if displayURLs.contains(where: { $0.caseInsensitiveCompare("") == .orderedSame }) {
                    rank = -1
                    continue
                }
                rank += 1
            }

            // compare to best rank
            if rank > bestRank {
                bestRank = rank // update rank
                bestFace = face // update best face
            }

        }

        return bestFace

    }

}
