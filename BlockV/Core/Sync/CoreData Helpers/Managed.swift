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

public protocol Managed: class, NSFetchRequestResult {
    static var entity: NSEntityDescription { get }
    static var entityName: String { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
    static var defaultPredicate: NSPredicate { get }
    var managedObjectContext: NSManagedObjectContext? { get }
}

public protocol DefaultManaged: Managed {}

extension DefaultManaged {
    public static var defaultPredicate: NSPredicate { return NSPredicate(value: true) }
}

extension Managed {
    
    public static var defaultSortDescriptors: [NSSortDescriptor] { return [] }
    public static var defaultPredicate: NSPredicate { return NSPredicate(value: true) }
    
    public static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        request.predicate = defaultPredicate
        return request
    }
    
    public static func sortedFetchRequest(with predicate: NSPredicate) -> NSFetchRequest<Self> {
        let request = sortedFetchRequest
        guard let existingPredicate = request.predicate else { fatalError("must have predicate") }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [existingPredicate, predicate])
        return request
    }
    
    public static func predicate(format: String, _ args: CVarArg...) -> NSPredicate {
        let p = withVaList(args) { NSPredicate(format: format, arguments: $0) }
        return predicate(p)
    }
    
    public static func predicate(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [defaultPredicate, predicate])
    }
    
}


public extension Managed where Self: NSManagedObject {
    
    public static var entity: NSEntityDescription { return entity()  }
    
    public static var entityName: String { return entity.name!  }
    
    /// Fetches the entity from the context, if not found, a new entity is created using the configuration.
    ///
    /// Performance:
    /// - Short circiut optimazation stays in the Context Tier (fast).
    /// - Fetch request will drop into the Coordinator Tier (row cache) and possibly the SQL Tier (slow).
    static func findOrCreate(in context: NSManagedObjectContext, matching predicate: NSPredicate, configure: (Self) -> ()) -> Self {
        // checks 'in-memory' before executing a fetch request.
        guard let object = findOrFetch(in: context, matching: predicate) else {
            let newObject: Self = context.insertObject()
            configure(newObject)
            return newObject
        }
        return object
    }
    
    /// Returns the first object matching the given predicate.
    ///
    /// Attempts to short circuit into context's set of materialized objects, if not matches, then exexutes a fetch request.
    ///
    /// Performance:
    /// - Short circiut optimazation stays in the Context Tier (fast).
    /// - Fetch request will drop into the Coordinator Tier (row cache) and possibly the SQL Tier (slow).
    static func findOrFetch(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        
        // check if there is a mathching materialized object
        guard let object = materializedObject(in: context, matching: predicate) else {
            // otherwise, execute fetch request
            return fetch(in: context) { request in
                request.predicate = predicate
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                }.first
        }
        return object
    }
    
    /// Fetches the enitiy from the context.
    ///
    /// This will incur a full round trip to the persistent store.
    ///
    /// Prefer `findOrFetch(in: matching:)`
    public static func fetch(in context: NSManagedObjectContext, configurationBlock: (NSFetchRequest<Self>) -> () = { _ in }) -> [Self] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        configurationBlock(request)
        return try! context.fetch(request)
    }
    
    public static func count(in context: NSManagedObjectContext, configure: (NSFetchRequest<Self>) -> () = { _ in }) -> Int {
        let request = NSFetchRequest<Self>(entityName: entityName)
        configure(request)
        return try! context.count(for: request)
    }
    
    /// Finds any already materialized (i.e. non-fault) objects that match the given predicate.
    ///
    /// Itereates over the context's registeredObjects set which contains all the managed objects the context
    /// currently knows about. Does not fault (this prevents a round trip to the persistent store).
    ///
    /// Performance:
    /// Only evaluates the Context Tier - and does not fulfill faults (fast).
    static func materializedObject(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        
        for object in context.registeredObjects where !object.isFault {
            guard let result = object as? Self, predicate.evaluate(with: result) else { continue }
            return result
        }
        return nil
    }
    
}

extension Managed where Self: NSManagedObject {
    
    /// Tries to retrieve the object from the cache in the context's userInfor. If there is nothing in the cache, it calls a private method,
    /// which actually executes the fetch request.
    public static func fetchSingleObject(in context: NSManagedObjectContext, cacheKey: String, configure: (NSFetchRequest<Self>) -> ()) -> Self? {
        if let cached = context.object(forSingleObjectCacheKey: cacheKey) as? Self { return cached
        }
        let result = fetchSingleObject(in: context, configure: configure)
        context.set(result, forSingleObjectCacheKey: cacheKey)
        return result
    }
    
    
    fileprivate static func fetchSingleObject(in context: NSManagedObjectContext, configure: (NSFetchRequest<Self>) -> ()) -> Self? {
        let result = fetch(in: context) { request in
            configure(request)
            request.fetchLimit = 2
        }
        switch result.count {
        case 0: return nil
        case 1: return result[0]
        default: fatalError("Returned multiple objects, expected max 1")
        }
    }
}

// MARK: - Cameron

protocol JSONUpdatable: Managed where Self: NSManagedObject {
    
    static func update(into context: NSManagedObjectContext, with descriptor: [String: Any]) throws -> Self

}

public extension Managed where Self: NSManagedObject {
    
    /// Deletes all objects of type `Self` from the store.
    ///
    /// - important
    /// This is efficient for mass updates, but places the resposibility of on the caller to ensure the data in the managed object context and the row
    /// cache gets updated.
    /// To resolve this, see: Pg. 104
    ///
    /// - issue
    /// This delete will only proagrate into the context that is passed in. Other contexts will still have the deleted objects.
    /// This will need to be propagated into them.
    static func deleteAllObjects(in context: NSManagedObjectContext) {
        
        //see: https://stackoverflow.com/questions/1383598/core-data-quickest-way-to-delete-all-instances-of-an-entity
        
        let request = self.fetchRequest()
        request.includesPropertyValues = false
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            deleteRequest.resultType = .resultTypeObjectIDs
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            if let objectIDArray = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDArray]
                // by calling mergeChangesFromRemoteContextSave, all instances of NSManagedObjectContext that are
                // referenced will be notified that the list of entires referenced with the NSManagedObjectID array
                // have been deleted and that the objects in memory are stale.
                // this causes the referenced `NSManagedObjectContext` instances to remove any objects in memory matching the set of ids
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
            try context.save()
        } catch {
            print(error)
            //FIXME: Handle error
        }
        
    }
    
}
