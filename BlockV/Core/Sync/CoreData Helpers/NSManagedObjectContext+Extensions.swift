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
    
    private var store: NSPersistentStore {
        guard let psc = persistentStoreCoordinator else { fatalError("PSC missing") }
        guard let store = psc.persistentStores.first else { fatalError("No Store") }
        return store
    }
    
    public var metaData: [String: AnyObject] {
        get {
            guard let psc = persistentStoreCoordinator else { fatalError("must have PSC") }
            return psc.metadata(for: store) as [String : AnyObject]
        }
        set {
            performChanges {
                guard let psc = self.persistentStoreCoordinator else { fatalError("PSC missing") }
                psc.setMetadata(newValue, for: self.store)
            }
        }
    }
    
    public func setMetaData(object: AnyObject?, forKey key: String) {
        var md = metaData
        md[key] = object
        metaData = md
    }
    
    public func insertObject<A: NSManagedObject>() -> A where A: Managed {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A else { fatalError("Wrong object type") }
        return obj
    }
    
    /// Attempts to save the managed object context.
    ///
    /// If the save fails, all changes in the context are rolled back.
    public func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        } catch {
            rollback()
            return false
        }
    }
    
    public func performSaveOrRollback() {
        perform {
            _ = self.saveOrRollback()
        }
    }
    
    public func performChanges(block: @escaping () -> ()) {
        perform {
            block()
            _ = self.saveOrRollback()
        }
    }
    
}


private let SingleObjectCacheKey = "SingleObjectCache"
private typealias SingleObjectCache = [String: NSManagedObject]

extension NSManagedObjectContext {
    
    /*
     The setter and getter below allow an object to be placed in the context's `userInfo` dictionary. This will ensure
     there's always a strong reference to the object. This acts are a cache by ensuring the object is always present
     in the persistent store's row cache and context's registeredObject once accessed.
     */
    
    /// Sets a managed object on the context using a cache key.
    ///
    /// This object will be strongly referenced by it's context and there for will remain cached and therefore fast to access.
    /// This is usefull for very commonly accessed object e.g. currently logged in user.
    ///
    /// This method should be used sparingly since it will increase memeory usage and counteract Core Data's internal memory saving behavours.
    public func set(_ object: NSManagedObject?, forSingleObjectCacheKey key: String) {
        var cache = userInfo[SingleObjectCacheKey] as? SingleObjectCache ?? [:]
        cache[key] = object
        userInfo[SingleObjectCacheKey] = cache
    }
    
    /// Gets a managed object on the context using a cache key.
    ///
    /// Fetches the managed object from the context's cache.
    public func object(forSingleObjectCacheKey key: String) -> NSManagedObject? {
        guard let cache = userInfo[SingleObjectCacheKey] as? [String:NSManagedObject] else { return nil }
        return cache[key]
    }
}

