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

/*
 This file is full of experiments, nothing concrete yet.
 */

/// Idea:
/// - This is a catch all for all actions that don't have their own change processor.
final class VatomActionProcessor: ElementChangeProcessor {

    var elementsInProgress = InProgressTracker<VatomCD>()

    func setup(for context: ChangeProcessorContext) {
        // no-op
    }
    
    func processChangedLocalElements(_ elements: [VatomCD], in context: ChangeProcessorContext) {
        //
    }
    
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) where T : RemoteRecord {
        // no-op
        completion()
    }
    
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
        // no-op
    }
    
    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = VatomCD.markedForRemoteDeletionPredicate
        let notDeleted = VatomCD.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }
    
}

extension VatomActionProcessor {
    
    fileprivate func processActionedVatoms() {
        
    }
    
}


public protocol RemoteActionable: class {
    func markForRemoteAction()
    var markedForRemoteAction: Bool { get set }
}
