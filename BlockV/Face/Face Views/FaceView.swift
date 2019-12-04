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

/// TODO: This operator is useful, but has a drawback in that it always makes an assignment.
infix operator ?=
internal func ?=<T> (lhs: inout T, rhs: T?) {
    lhs = rhs ?? lhs
}

/// Types seeking to present a vatom using a face should conform to this protocol.
public protocol FacePresenter: class {
    
    var vatom: VatomModel { get }
    
    var faceModel: FaceModel { get }
    
}

/// Composite type that all face views must derive from and conform to.
///
/// A face view is responsile for rendering a single face of a vAtom.
public typealias FaceView = BaseFaceView & FaceViewLifecycle & FaceViewIdentifiable

/// The protocol that face view must adopt to be uniquely identified.
public protocol FaceViewIdentifiable {

    /// Uniqiue identifier of the face view.
    ///
    /// This id is used to register the face in the face roster. The face roster is an input to the
    /// `FaceSelectionProcedure` type.
    static var displayURL: String { get }

}

/// The protocol that face views must adopt to receive lifecycle events.
///
///  When implementing a Face View, it is worth considering how it will work for both owned and unowned (public) vAtoms.
public protocol FaceViewLifecycle: class {

    /// Boolean value indicating whether the face view has loaded. After load has completed that boolean must be
    /// updated.
    var isLoaded: Bool { get }

    /// Called to initiate the loading of the face view.
    ///
    /// All content and state should be reset on calling load.
    ///
    /// - important:
    /// This method will only be called only once by the Vatom View Life Cycle (VVLC). This is the trigger for the face
    /// view to gathering necessary resources and lay out its content.
    ///
    /// Face views *must* call the completion handler once loading has completed or errored out.
    func load(completion: ((Error?) -> Void)?)

    /*
     # NOTE
     
     The face model is set only on init. Vatom by comparison is may be updated over the lifetime of the face view.
     This means if a change has been made to the template's actions and faces (after init) those changes will not
     be incorporated.
     
     Perhaps vatomChanged(_ vatom:  VatomModel) should be updated to accept the face model for the rare case it has
     changed? That said, modifiying the faces after init is bad proactice.
     */

    /// Called to inform the face view the specified vAtom should be rendered.
    ///
    /// Face views should respond to this method by refreshing their content. Typically, this is achieved by internally
    /// calling the load method.
    ///
    /// Animating changes:
    /// If the vatom id has not changed, consider animating the state change.
    ///
    /// - important:
    /// This method may be called multiple times by the Vatom View Life Cycle (VVLC). It is important to reset the
    /// contents of the face view when so that the new state of the Vatom can be shown.
    ///
    /// - note:
    /// This method does not guarantee the same vAtom will be passed in. Rather, it guarantees that the vatom passed
    /// in will, at minimum, share the same template variation. This is typically encountered when VatomView is used
    /// inside a reuse pool such as those found in `UICollectionView`.
    ///
    /// ### Use case
    /// This may be called in response to numerous system events. Action handlers, brain code, etc. may all affect the
    /// vAtom's root or private section. VatomView passes these updates on to the face view.
    func vatomChanged(_ vatom: VatomModel)

    /// Called to reset the content of the face view.
    ///
    /// - important:
    /// This event may be called multiple times.
    ///
    /// The face view should perform a clean up operation, e.g. cancel all downloads, remove any listers, nil out any
    /// references. Call unload before dealloc.
    func unload()

}

/// Abstract class all face views must derive from.
open class BaseFaceView: BoundedView, FacePresenter {

    /// Vatom to render.
    public var vatom: VatomModel

    /// Face model to render.
    public internal(set) var faceModel: FaceModel

    /// Face view delegate.
    weak public internal(set) var delegate: FaceViewDelegate?

    /// Initializes a BaseFaceView using a vAtom and a face model.
    ///
    /// Use the initializer purely to configure the face view. Use the `load` lifecycle method to begin heavy operations
    /// to update the state of the face view, e.g. downloading resources.
    public required init(vatom: VatomModel, faceModel: FaceModel) throws {
        self.vatom = vatom
        self.faceModel = faceModel
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

/// Models the errors that may be thrown by face views.
public enum FaceError: Error {
    case missingVatomResource
    case invalidURL
    case failedToLoadResource
}

// MARK: - Triggers

public enum TriggerType {
    case animation
    case sound
    case action
}

public extension FacePresenter {
    
    /// Returns all trigger rules for the speicifed event and constraints.
    func findAllTriggerRules(forEvent event: CommonFaceConfig.OnEvent,
                             animationRule: CommonFaceConfig.TriggerRule?,
                             actionName: String?) -> [CommonFaceConfig.TriggerRule] {
    
        var triggers: [CommonFaceConfig.TriggerRule] = []
        //TODO: Optimize into one loop
        triggers += self.findAnimationRules(forEvent: event, animationRule: animationRule, actionName: actionName)
        triggers += self.findSoundRules(forEvent: event, animationRule: animationRule, actionName: actionName)
        triggers += self.findActionRules(forEvent: event, animationRule: animationRule, actionName: actionName ?? "dev/null")
        return triggers
        
    }
    
    /// Returns all trigger rules of the specified type.
    func findAllTriggerRules(ofType type: TriggerType) -> [CommonFaceConfig.TriggerRule] {
        
        guard
            let config = self.faceModel.properties.config,
            let triggerRules = config.animation_rules?.arrayValue
            else { return [] }
        
        return triggerRules.compactMap {
            switch type {
            case .animation: if ($0.play?.stringValue).isNilOrEmpty { return nil }
            case .sound: if ($0.sound?.objectValue).isNilOrEmpty { return nil }
            case .action: if ($0.action?.objectValue).isNilOrEmpty { return nil }
            }
            return try? CommonFaceConfig.TriggerRule(descriptor: $0)
        }
    }
    
    /// Returns the first animation rule for the triggering event.
    ///
    /// - Parameters:
    ///   - event: Triggering event.
    ///   - currentAnimation: Currently playing animation. Pass in `nil` to indicate no anmiation is currently playing.
    ///                       For `animationComplete`, pass in the now completed animation as the `currentAnimation`.
    /// - Returns: Animation name, or `nil` if none of the rules match the criteria.
    func findFirstAnimationRule(forEvent event: CommonFaceConfig.OnEvent,
                                animationRule: CommonFaceConfig.TriggerRule?,
                                actionName: String?) -> CommonFaceConfig.TriggerRule? {
        
        return findAnimationRules(forEvent: event, animationRule: animationRule, actionName: actionName).first ?? nil
        
    }
    
    private func findAnimationRules(forEvent event: CommonFaceConfig.OnEvent,
                            animationRule: CommonFaceConfig.TriggerRule?,
                            actionName: String?) -> [CommonFaceConfig.TriggerRule] {
        
        // only consider rules matching the event type
        let allAnimationRules = findAllTriggerRules(ofType: .animation)
        let candidateRules = allAnimationRules.filter { ($0.on == event.rawValue) }
        return self.filterRules(candidateRules, forEvent: event, animationRule: animationRule, actionName: actionName)
        
    }
    
    /// Finds valid sound rules for the given event.
    func findSoundRules(forEvent event: CommonFaceConfig.OnEvent,
                        animationRule: CommonFaceConfig.TriggerRule?,
                        actionName: String?) -> [CommonFaceConfig.TriggerRule] {
        
        // only consider rules matching the event type
        let allSoundnRules = findAllTriggerRules(ofType: .sound)
        let candidateRules = allSoundnRules.filter { ($0.on == event.rawValue) }
        return self.filterRules(candidateRules, forEvent: event, animationRule: animationRule, actionName: actionName)
        
    }
    
    /// Finds the first action rule for the given event.
    func findFirstActionRule(forEvent event: CommonFaceConfig.OnEvent,
                        animationRule: CommonFaceConfig.TriggerRule?,
                        actionName: String) -> CommonFaceConfig.TriggerRule? {
        return findActionRules(forEvent: event, animationRule: animationRule, actionName: actionName).first ?? nil
    }
    
    private func findActionRules(forEvent event: CommonFaceConfig.OnEvent,
                         animationRule: CommonFaceConfig.TriggerRule?,
                         actionName: String) -> [CommonFaceConfig.TriggerRule] {
        
        // only consider rules matching the event type
        let allSoundnRules = findAllTriggerRules(ofType: .action)
        let candidateRules = allSoundnRules.filter { ($0.on == event.rawValue) }
        return filterRules(candidateRules, forEvent: event, animationRule: animationRule, actionName: actionName)
        
    }
    
    private func filterRules(_ candidateRules: [CommonFaceConfig.TriggerRule],
                             forEvent event: CommonFaceConfig.OnEvent,
                             animationRule: CommonFaceConfig.TriggerRule?,
                             actionName: String?) -> [CommonFaceConfig.TriggerRule] {
        
        // loop over animation rules
        switch event {
            
        case .start:
            // find valid state rules, fallback on start rule
            let stateRules = findAllTriggerRules(forEvent: .state, animationRule: animationRule, actionName: actionName)
            let rulls = stateRules.isEmpty ? candidateRules: stateRules
            print("[xxx]", rulls)
            return rulls
        case .state:
            return candidateRules.filter { rule in
                // ensure both `target` and `value` have been set
                guard let value = rule.value, let target = rule.target else { return false }
                // filter in rules where the vatom's value matches the animation rules value
                if let vatomValue = self.vatom.valueForKeyPath(target), vatomValue == value {
                    return true
                }
                return false
            }
        case .click:
            let validRules = candidateRules.filter { rule in
                if let target = rule.target {
                    
                    if target.isEmpty && animationRule == nil {
                        return true
                    }
                    if !target.isEmpty, target == animationRule?.play {
                        return true
                    }
                    return false
                } else {
                    return true // target is null
                }
            }
            return validRules
        case .animationStart:
            // filter in rules whos target matches to be played animation rule.
            return candidateRules.filter { $0.target == animationRule?.play }
        case .animationComplete:
            // filter in rules whos target matches the completed animation rule.
            return candidateRules.filter { $0.target == animationRule?.play }
        case .actionComplete:
            // filter in rules whos target matches the event's action
            return candidateRules.filter { $0.target == actionName }
        case .actionFail:
            // filter in rules whos target matches the event's action
            return candidateRules.filter { $0.target == actionName }
        }
        
    }
    
}

extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
