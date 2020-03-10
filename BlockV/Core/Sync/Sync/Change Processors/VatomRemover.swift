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

import os
import CoreData

final class VatomRemover: ElementChangeProcessor {
    
    var elementsInProgress = InProgressTracker<VatomCD>()
    
    func setup(for context: ChangeProcessorContext) {
        // no-op
    }
    
    func processChangedLocalElements(_ elements: [VatomCD], in context: ChangeProcessorContext) {
        processDeletedVatom(elements, context: context)
    }
    
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
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

extension VatomRemover {
    
    /*
     I have altered the logic here slighty, I do not have local-only vatom (without a remote identifier).
     NB* Server must give us a batch delete endpoint.
     */
    
    fileprivate func processDeletedVatom(_ deletions: [VatomCD], context: ChangeProcessorContext) {
        let allObject = Set(deletions)
        deleteRemotely(allObject, context: context)
    }
    
    fileprivate func deleteLocally(_ deletions: Set<VatomCD>, context: ChangeProcessorContext) {
        deletions.forEach { $0.markForLocalDeletion() }
    }
    
    fileprivate func deleteRemotely(_ deletions: Set<VatomCD>, context: ChangeProcessorContext) {
        
        //TODO: This is dangerous for a large number of deletions, the server should rather give us an endpoint
        // to delete an array of vatoms.
        for deletion in deletions {
            context.remote.trashVatom(deletion.id) { error in
                
                if let error = error {
                    /*
                     FIXME: Stopping conditions are very important to prevent loops!
                     1. Why does an error cause a loop?
                     2. Under what conditions (e.g. remote fails to delete) should the vatom be deleted locally?
                     */
                    
                    if case BVError.platform(reason: .vatomPermissionUnauthorized(_, _, _)) = error {
                        os_log("[%@] Remote delete failed on %@. Deleting locally anyway. Error: %@", log: .sync,
                               type: .error, typeName(self), deletion.id, error.localizedDescription)
                        self.deleteLocally([deletion], context: context)
                    }
                } else {
                    // delete locally if no error
                    os_log("[%@] Local delete: %@", log: .sync, type: .info, typeName(self), deletion.id)
                    self.deleteLocally([deletion], context: context)
                }
                
                /*
                 There is a state machine at work with change processors.
                */
                
                // mark changes as complete, failed deletions will be retired
                self.didComplete(Array(deletions), in: context)
                context.delayedSaveOrRollback()
            }
        }
    }
    
}
