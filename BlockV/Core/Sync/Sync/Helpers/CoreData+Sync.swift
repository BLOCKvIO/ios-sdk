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


extension NSManagedObjectContext {
    
    /// Performs a given block on the context’s queue.
    ///
    /// The group is entered immediately, however the task will only begin when the backing queue processes the block.
    /// The group is exited once the block has been processed.
    func perform(group: DispatchGroup, block: @escaping () -> Void) {
        group.enter()
        perform {
            block()
            group.leave()
        }
    }
    
    func performAsync(group: DispatchGroup, block: @escaping (_ completion: () -> Void) -> Void) {
        group.enter()
        perform {
            block {
                group.leave()
            }
        }
    }
}


extension Sequence where Iterator.Element: NSManagedObject {
    
    /// Returns a sequnce of objects created and ready for use on the provided context.
    ///
    /// This function is useful so as not to break the golden rule of mutiple contexts:
    /// Objects created on one context's queue must not be used on another context's queue.
    func remap(to context: NSManagedObjectContext) -> [Iterator.Element] {
        return map { unmappedMO in
            guard unmappedMO.managedObjectContext !== context else { return unmappedMO }
            guard let object = context.object(with: unmappedMO.objectID) as? Iterator.Element else { fatalError("Invalid object type") }
            return object
        }
    }
}


extension NSManagedObjectContext {
    
    /// Count of changed (inserted, updated, and deleted) objects in the context.
    fileprivate var changedObjectsCount: Int {
        return insertedObjects.count + updatedObjects.count + deletedObjects.count
    }
    
    /// Delays the save operation until the group is empty.
    ///
    /// This way, as long as the sync code is busy, and the `changeCountLimit` has not been exceeded, saves will get delayed.
    func delayedSaveOrRollback(group: DispatchGroup, completion: @escaping (Bool) -> () = { _ in }) {
        let changeCountLimit = 100
        guard changeCountLimit >= changedObjectsCount else { return completion(saveOrRollback()) }
        let queue = DispatchQueue.global(qos: .default) //TODO: Why is this called on a global default queue?
        // wait for the group to be empty
        group.notify(queue: queue) {
            self.perform(group: group) {
                guard self.hasChanges else { return completion(true) }
                completion(self.saveOrRollback())
            }
        }
    }
}

