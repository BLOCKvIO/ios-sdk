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

import CoreData

/// Implements the integration with Core Data change notifications.
///
/// This protocol merges changes from the view context into the sync context and vice versa.
/// It calls its `process(changedLocalObjects:)` methods when objects have changed.
protocol ContextOwner: class, ObserverTokenStore {
    /// The view managed object context.
    var viewContext: NSManagedObjectContext { get }
    /// The managed object context that is used to perform synchronization with the backend.
    var syncContext: NSManagedObjectContext { get }
    /// This group tracks any outstanding work.
    var syncGroup: DispatchGroup { get }
    
    /// Will be called whenever objects on the sync managed object context have changed.
    func processChangedLocalObjects(_ objects: [NSManagedObject])
}


extension ContextOwner {

    func setupContexts() {
        setupQueryGenerations()
        setupContextNotificationObserving()
    }
    
    fileprivate func setupQueryGenerations() {
        let token = NSQueryGenerationToken.current
        viewContext.perform {
            try! self.viewContext.setQueryGenerationFrom(token)
        }
        syncContext.perform {
            try! self.syncContext.setQueryGenerationFrom(token)
        }
    }
    
    /// Setup reconciliation between the view and sync contexts.
    fileprivate func setupContextNotificationObserving() {
        addObserverToken(
            viewContext.addContextDidSaveNotificationObserver { [weak self] note in
                self?.viewContextDidSave(note)
            }
        )
        addObserverToken(
            syncContext.addContextDidSaveNotificationObserver { [weak self] note in
                self?.syncContextDidSave(note)
            }
        )
        addObserverToken(
            syncContext.addObjectsDidChangeNotificationObserver { [weak self] note in
                self?.objectsInSyncContextDidChange(note)
        })
    }
    
    /// Merge local changes from view -> sync context.
    fileprivate func viewContextDidSave(_ note: ContextDidSaveNotification) {
        syncContext.performMergeChanges(from: note)
        notifyAboutChangedObjects(from: note)
    }
    
    /// Merge local changes from sync -> view context.
    fileprivate func syncContextDidSave(_ note: ContextDidSaveNotification) {
        viewContext.performMergeChanges(from: note)
        notifyAboutChangedObjects(from: note)
    }
    
    fileprivate func objectsInSyncContextDidChange(_ note: ObjectsDidChangeNotification) {
        // no-op
    }
    
    /// Forward notification (after contexts are locally sync'd) to all change processors.
    ///
    /// Change processors are executes on the syncContext's queue.
    fileprivate func notifyAboutChangedObjects(from notification: ContextDidSaveNotification) {
        // change processors are run on the sync context
        syncContext.perform(group: syncGroup) {
            // We unpack the notification here, to make sure it's retained
            // until this point.
            let updates = notification.updatedObjects.remap(to: self.syncContext)
            let inserts = notification.insertedObjects.remap(to: self.syncContext)
            // distribute objects to all change processors
            self.processChangedLocalObjects(updates + inserts)
        }
    }
}

