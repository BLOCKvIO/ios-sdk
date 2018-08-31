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
/// faces associated with the vatom's template. It is an algorithm that assists a vAtom in selecting the best face for
/// a specific visual context.
///
/// An FSP gives the Viewer optional control over the face selection procedure.
///
/// Closure inputs:
/// - vAtom to be displayed.
/// - Actions associated with the vAtom's template.
/// - Faces associated with the vAtom's template.
/// - Installed display URLs. This is the set of native face display URLs (i.e. unique identifiers of the installed
///   native faces).
///
/// Closure ouput:
/// - Optional face model. The closure should return the 'best' face given the inputs, or `nil` if no face is selected.
///
/// - Parameters:
///   - vatomPack: vAtom pack from which the best face model should be selected.
///   - installedURLs: Set of displayURLs of the installed face views.
public typealias FaceSelectionProcedure = (_ vatomPack: VatomPackModel, _ installedURLs: Set<String>)
    -> FaceModel?

/// Models the embedded face selection procedures (FSP)s. This is a set of pre-built face selection procedures defined
/// by the SDK to meet common use cases.
///
/// It important to think of the cases simply as unique identifiers of stored face selection procedures. Cases loosely
/// map to the server's 'view_mode' simply because the 'view_mode' is generally the predominant selection criteria.
///
/// Embedded procedures:
/// 1. find faces meeting the 'view mode' requirement
/// 2. prefer platform specialized (iOS) faces over generic
/// 3. prefer 'native' over 'web' faces
/// 4. ensure native face code is installed
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

    //    /// Selects the 'best' face using this procedure's stored Face Selection Procedure (FSP).
    //    ///
    //    /// - Parameters:
    //    ///   - vatomPack: vAtom pack from which the best face should be selected.
    //    ///   - displayURLs: Set of display URLs of the installed native faces.
    //    ///   - useFallback: Determines whether the fallback procedure should be used. If `true` the fallback is used,
    //    ///   `false` otherwise.
    //    /// - Returns: The selected face model, or `nil` if no face model is selected.
    //    func selectBestFace(vatomPack: VatomPackModel, displayURLs: Set<String>, useFallback: Bool = true)
    //        -> FaceModel? {
    //            // execute this procedure, use fallback if necessary
    //            return self.selectionProcedure(vatomPack, displayURLs) ??
    //                self.fallback?.selectionProcedure(vatomPack, displayURLs)
    //    }

}

/// Struct responsible for buidling the embedded procedures.
private struct EmbeddedProcedureBuilder {

    // MARK: - Stored Face Selection Procedure (FSP) + Fallback

    static let iconProcedureWithFallback: FaceSelectionProcedure = { (vatomPack, installedURLs) in
        return EmbeddedProcedureBuilder.iconProcedure(vatomPack, installedURLs) ??
            EmbeddedProcedure.icon.fallback?.procedure(vatomPack, installedURLs)
    }

    static let engagedProcedureWithFallback: FaceSelectionProcedure = { (vatomPack, installedURLs)  in
        return EmbeddedProcedureBuilder.engagedProcedure(vatomPack, installedURLs) ??
            EmbeddedProcedure.engaged.fallback?.procedure(vatomPack, installedURLs)
    }

    static let fullscreenProcedureWithFallack: FaceSelectionProcedure = { (vatomPack, installedURLs)  in
        return EmbeddedProcedureBuilder.fullscreenProcedure(vatomPack, installedURLs) ??
            EmbeddedProcedure.fullscreen.fallback?.procedure(vatomPack, installedURLs)
    }

    static let cardProcedureWithFallack: FaceSelectionProcedure = { (vatomPack, installedURLs)  in
        return EmbeddedProcedureBuilder.cardProcedure(vatomPack, installedURLs) ??
            EmbeddedProcedure.card.fallback?.procedure(vatomPack, installedURLs)
    }

    // MARK: - Face Selection Procedures (FSP)

    static let iconProcedure: FaceSelectionProcedure = { (vatomPack, installedURLs) in
        EmbeddedProcedureBuilder.defaultSelectionProcedure(vatomPack.faces,
                                                           installedURLs,
                                                           EmbeddedProcedure.icon.constraints)
    }

    static let engagedProcedure: FaceSelectionProcedure = { (vatomPack, installedURLs)  in
        EmbeddedProcedureBuilder.defaultSelectionProcedure(vatomPack.faces,
                                                           installedURLs,
                                                           EmbeddedProcedure.engaged.constraints)
    }

    static let fullscreenProcedure: FaceSelectionProcedure = { (vatomPack, installedURLs)  in
        EmbeddedProcedureBuilder.defaultSelectionProcedure(vatomPack.faces,
                                                           installedURLs,
                                                           EmbeddedProcedure.fullscreen.constraints)
    }

    static let cardProcedure: FaceSelectionProcedure = { (vatomPack, installedURLs)  in
        EmbeddedProcedureBuilder.defaultSelectionProcedure(vatomPack.faces,
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

            // prefer 'native' over 'web'
            if face.isNative {

                // enusrue the native face is supported (i.e. the face code is installed)
                if installedURLs.contains(where: {
                    ($0.caseInsensitiveCompare(face.properties.displayURL.absoluteString) == .orderedSame) }) {
                    rank += 1
                } else {
                    // native code is not installed
                    continue
                }

            }

            //TODO: Check if web face is installed

            // compare to best rank
            if rank > bestRank {
                bestRank = rank // update rank
                bestFace = face // update best face
            }

        }

        return bestFace

    }

}