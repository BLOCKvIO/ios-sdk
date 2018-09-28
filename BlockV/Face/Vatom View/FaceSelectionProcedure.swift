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

/// A Face Selection Procedure (FSP) is an algorithm used to select the best face model from the (potentially) many
/// faces models associated with the vatom's template. It is an algorithm that assists a vAtom in selecting the best
/// face for a specific visual context.
///
/// Closure inputs:
/// - Packed vAtom to be displayed.
/// - Installed display URLs. This is the set of native face display URLs (i.e. unique identifiers of the installed
///   native faces).
///
/// Closure ouput:
/// - Optional face model. The closure should return the 'best' face given the inputs, or `nil` if no face is selected.
///
///
/// - important:
/// Procedures should:
/// 1. filter for faces meeting the 'view mode' requirement,
/// 2. prefer platform specialized (iOS) faces over generic,
/// 3. prefer 'native' over 'web' faces, and
/// 4. ensure face view code is registered.
///
/// Procedures should not:
/// 1. validate vAtom private properties,
/// 2. validate vAtom resources,
/// 3. validate vAtom face model config.
/// > Rather, this validation is left to the face code to display an error.
///
/// - Parameters:
///   - vatom: Packed vAtom from which the best face model should be selected from the vatom's packaged faces.
///   - installedURLs: Set of displayURLs of the installed face views.
public typealias FaceSelectionProcedure = (_ vatom: VatomModel, _ installedURLs: Set<String>)
    -> FaceModel?

/// Models the embedded face selection procedures (FSP)s. This is a set of pre-built face selection procedures defined
/// by the SDK to meet common use cases.
///
/// It is important to think of the cases simply as unique identifiers of stored face selection procedures. Cases
/// loosely map to the server's 'view_mode' simply because the 'view_mode' is generally the predominant selection
/// criteria.
public enum EmbeddedProcedure {

    /// Selects based on 'icon' view mode.
    case icon
    /// Selects based on 'engaged' view mode.
    case engaged
    /// Selects based on 'fullscreen' view mode.
    case fullscreen
    /// Selects based on 'card' view mode.
    case card

    /// A fallback allows one procedure to fallback on another (in the event the first procedure fails to select a
    /// face model).
    /// This logic is specific to the embeed procedures.
    var fallback: EmbeddedProcedure? {
        switch self {
        case .icon:         return nil
        case .engaged:      return .icon
        case .fullscreen:   return nil
        case .card:         return nil
        }
    }

    /// Returns the face selection procedure.
    ///
    /// Runs a fallback procedure if one is specified on `fallback`.
    public var procedure: FaceSelectionProcedure {
        switch self {
        case .icon:             return EmbeddedProcedureBuilder.iconProcedureWithFallback
        case .engaged:          return EmbeddedProcedureBuilder.engagedProcedureWithFallback
        case .fullscreen:       return EmbeddedProcedureBuilder.fullscreenProcedureWithFallack
        case .card:             return EmbeddedProcedureBuilder.cardProcedureWithFallack
        }
    }

    // MARK: Constraints

    /// Constraints associated with this embedded procedure.
    var constraints: SelectionConstraints {
        switch self {
        case .icon:         return SelectionConstraints(viewMode: "icon")
        case .engaged:      return SelectionConstraints(viewMode: "engaged")
        case .fullscreen:   return SelectionConstraints(viewMode: "fullscreen")
        case .card:         return SelectionConstraints(viewMode: "card")
        }
    }

    /// Constraints used as the selection criteria when choosing the best face for this procedure.
    struct SelectionConstraints {
        /// The view_mode of the face.
        let viewMode: String
        // let quality: String // e.g. of futher constraints
    }

}

/// Struct responsible for buidling the embedded procedures.
private struct EmbeddedProcedureBuilder {

    // MARK: - Stored Face Selection Procedure (FSP) + Fallback

    static let iconProcedureWithFallback: FaceSelectionProcedure = { (vatom, installedURLs) in
        return EmbeddedProcedureBuilder.iconProcedure(vatom, installedURLs) ??
            EmbeddedProcedure.icon.fallback?.procedure(vatom, installedURLs)
    }

    static let engagedProcedureWithFallback: FaceSelectionProcedure = { (vatom, installedURLs)  in
        return EmbeddedProcedureBuilder.engagedProcedure(vatom, installedURLs) ??
            EmbeddedProcedure.engaged.fallback?.procedure(vatom, installedURLs)
    }

    static let fullscreenProcedureWithFallack: FaceSelectionProcedure = { (vatom, installedURLs)  in
        return EmbeddedProcedureBuilder.fullscreenProcedure(vatom, installedURLs) ??
            EmbeddedProcedure.fullscreen.fallback?.procedure(vatom, installedURLs)
    }

    static let cardProcedureWithFallack: FaceSelectionProcedure = { (vatom, installedURLs)  in
        return EmbeddedProcedureBuilder.cardProcedure(vatom, installedURLs) ??
            EmbeddedProcedure.card.fallback?.procedure(vatom, installedURLs)
    }

    // MARK: - Face Selection Procedures (FSP)

    static let iconProcedure: FaceSelectionProcedure = { (vatom, installedURLs) in
        EmbeddedProcedureBuilder.defaultSelectionProcedure(vatom.faceModels,
                                                           installedURLs,
                                                           EmbeddedProcedure.icon.constraints)
    }

    static let engagedProcedure: FaceSelectionProcedure = { (vatom, installedURLs)  in
        EmbeddedProcedureBuilder.defaultSelectionProcedure(vatom.faceModels,
                                                           installedURLs,
                                                           EmbeddedProcedure.engaged.constraints)
    }

    static let fullscreenProcedure: FaceSelectionProcedure = { (vatom, installedURLs)  in
        EmbeddedProcedureBuilder.defaultSelectionProcedure(vatom.faceModels,
                                                           installedURLs,
                                                           EmbeddedProcedure.fullscreen.constraints)
    }

    static let cardProcedure: FaceSelectionProcedure = { (vatom, installedURLs)  in
        EmbeddedProcedureBuilder.defaultSelectionProcedure(vatom.faceModels,
                                                           installedURLs,
                                                           EmbeddedProcedure.card.constraints)
    }

    // MARK: - Stored Procedure

    /// Embedded procedures take in only face models, display urls, and a set of constraints (as this is all they need).
    ///
    /// - Parameters:
    ///   - faceModels: Array of face models to be used by the selection procedure.
    ///   - installedURLs: Set of display URLs of the installed face views.
    ///   - constraints: Struct holding face contraints to be used by the selection procedure.
    typealias EmbeddedFaceSelectionProcedure = (_ faceModels: [FaceModel],
        _ installedURLs: Set<String>,
        _ constraints: EmbeddedProcedure.SelectionConstraints)
        -> FaceModel?

    /// Default selection procedure.
    ///
    /// This is a simple face selection procedure that ranks faces relative to their peers:
    ///
    /// 1. Ensure the face supports the current view mode.
    /// 2. Prefer specialized faces over generic.
    /// 3. Prefer native faces over web.
    /// 4. Ensure native faces are supported (i.e. have native face code installed).
    /// 5. Select the 'best' face.
    ///
    /// This closure defines a procedure that is common to most embedded FSPs. The logic is therefor consoldated here.
    static let defaultSelectionProcedure: EmbeddedFaceSelectionProcedure = { (faceModels, installedURLs, constraints) in

        var bestFace: FaceModel?
        var bestRank = -1

        for face in faceModels {

            /*
             Question to answer:
             - Does this face meet the requirements of the FSP, if so, how does it compare to it's peers.
             */

            var rank = 0

            // ensure 'view mode' is supported
            if  constraints.viewMode != face.properties.constraints.viewMode {
                // face does not meet this visual context's constraints
                continue
            }

            // prefer specialized faces over generic
            if face.properties.constraints.platform == "ios" {
                rank += 2
            } else if face.properties.constraints.platform == "generic" {
                rank += 1
            } else {
                // platform not supported
                continue
            }

            if face.isNative {

                // enusrue the native face is supported (i.e. the face code is installed)
                if installedURLs.contains(where: {
                    ($0.caseInsensitiveCompare(face.properties.displayURL) == .orderedSame) }) {
                    // prefer 'native' over 'web'
                    rank += 1
                } else {
                    // native code is not installed
                    continue
                }

            }

            if face.isWeb {

                // enusrue the native face is supported (i.e. the face code is installed)
                if installedURLs.contains(where: {
                    ($0.caseInsensitiveCompare("https://*") == .orderedSame) }) {
                } else {
                    // native code is not installed
                    continue
                }

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
