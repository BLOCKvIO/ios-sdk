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
import CoreData

// MARK: - Change Processor -

/// A change processor performs a specific sync task, e.g. "download Vatom objects".
/// This is the (non-generic) interface that the `SyncCoordinator` sees.
///
/// Change processors use a predicate to match local objects. These matching objects are operated on by the change processor.
///
/// Only change processors should hold domain-specific knowledge.
protocol ChangeProcessor {
    
    /// Called at startup to give the processor a chance to configure itself.
    ///
    /// Called only once when the sync coordinator initializes.
    func setup(for context: ChangeProcessorContext)
    
    /// Respond to changes of locally inserted or updated objects.
    ///
    /// This gets called once the view context's changes get merged in the sync context.
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext)
    
    /// Respond to changes in remote records.
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ())
    
    /// Returns all objects which match this change processor's predicate. This allows the change processor to resume pending local changes.
    ///
    /// Upon launch these fetch requests are executed and the resulting objects are passed to `process(changedLocalObjects:)`.
    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>?
        
    /// Does the initial fetch from the remote.
    ///
    /// At startup, the sync coordinator calls this method to make sure that the change processor can retrieve any local
    /// or remote objects that still has to be sent to or retrieved from the cloud. Or, fetch all object from the server.
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext)

}

// MARK: - Change Processor Context -

/// The `SyncCoordinator` has a list of *change processors* (`ChangeProcessor`) which do the actual work.
/// Whenever a change happens the *sync coordinator* passes itself to the *change processors* as a *context* (`ChangeProcessorContext`).
/// This is the part of the sync coordinator that the change processors should have access to (the interface).
protocol ChangeProcessorContext: class {
    
    /// The managed object context to use
    var context: NSManagedObjectContext { get }
    
    var coordinatorGroup: DispatchGroup { get }
    
    //TODO: Add socket?
    
    /*
     Should the socket be passed all the way down to the change processor, this would allow granular pause. What
     stops different change processors from unpausing the queue (even though some change processor still wants it
     paused)? This needs some kind of lock..
     */
    
    /// The remote to use for syncing.
    var remote: RemoteInterface { get }
    
    /// Wraps a block such that it is run on the right queue.
    func perform(_ block: @escaping () -> ())
    
    /// Wraps a block such that it is run on the right queue.
    func perform<A, B>(_ block: @escaping (A, B) -> ()) -> (A, B) -> ()
    
    /// Wraps a block such that it is run on the right queue.
    func perform<A, B, C>(_ block: @escaping (A, B, C) -> ()) -> (A, B, C) -> ()
    
    /// Eventually saves the context. May batch multiple calls into a single call to `saveOrRollback()`.
    func delayedSaveOrRollback()
}

// MARK: - Element Change Processor -

/// This a generic sub-protocol that a change processors can implement.
///
/// It does the type matching and casting in order to keep this *Change Processor* code simple.
/// When implementing `ElementChangeProcessor`, implement
/// ```
/// func processChangedLocalElements(_:,context:)
/// var predicateForLocallyTrackedElements
/// ```
/// as a replacement for
/// ```
/// func process(changedLocalObjects:,context:)
/// func entityAndPredicateForLocallyTrackedObjects(in:)
/// ```
///
/// The `ElementChangeProcessor` makes sure that objects which are already in progress,
/// are not started a second time. And once they finish, it checks if they should be
/// processed a second time at that point in time.
///
/// The contract is that the implementation is such that objects no longer match the `predicateForLocallyTrackedElements` once they're actually complete.
protocol ElementChangeProcessor: ChangeProcessor {
    
    associatedtype Element: NSManagedObject, Managed
    
    /// Used to track if elements are already in progress.
    var elementsInProgress: InProgressTracker<Element> {get}
    
    /// Called when objects matching the predicate should be processed.
    ///
    /// Elements will have been added to `elementsInProgress` at this point. It is up to the conforming type to remove the elements by calling `markObjectsAsComplete(_objects:)`.O
    func processChangedLocalElements(_ elements: [Element], in context: ChangeProcessorContext)
    
    /// The elements that this change processor is interested in.
    /// Used by `entityAndPredicateForLocallyTrackedObjects(in:)`.
    var predicateForLocallyTrackedElements: NSPredicate { get }
}


extension ElementChangeProcessor {
    
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        // Filters the `NSManagedObjects` according to the `entityAndPredicateForLocallyTrackedObjects(in:)` and forwards the result to `processChangedLocalElements(_:context:completion:)`.
        let matching = objects.filter(entityAndPredicateForLocallyTrackedObjects(in: context)!)
        if let elements = matching as? [Element] {
            let newElements = elementsInProgress.objectsToProcess(from: elements)
            processChangedLocalElements(newElements, in: context)
        }
    }
    
    func didComplete(_ elements: [Element], in context: ChangeProcessorContext) {
        elementsInProgress.markObjectsAsComplete(elements)
        // Now check if they still match:
        let p = predicateForLocallyTrackedElements
        let matching = elements.filter(p.evaluate(with:))
        let newElements = elementsInProgress.objectsToProcess(from: matching)
        if newElements.count > 0 {
            processChangedLocalElements(newElements, in: context)
        }
    }
    
    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        let predicate = predicateForLocallyTrackedElements
        return EntityAndPredicate(entity: Element.entity(), predicate: predicate)
    }
}

