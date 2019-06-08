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
import PromiseKit

/*
 # Notes:
 
 ## Filter & Sort
 
 Both of these should become classes (which do not inherit from Region). They provide a 'view into' a region.
 
 Caller:
 
 DataPool.region(id: "inventory", descriptor: [:]).filter { $0.dateModified > a }
 DataPool.region(id: "inventory", descriptor: [:]).sort { $0.title }
 
 Adding sort directly to Region is hard beacuse multiple callers may use use the same regions - all with different
 sorting predicates. So sorting must be cofigurable (isolated) per caller.
 
 */

/// An abstract class that manages a complete collection of objects (a.k.a Regions).
///
/// Regions are generally "id-complete". That is, the local region should have a complete copy of all remote objects.
///
/// Roles:
/// - In memory store of objects.
/// - Keep track of synchornization state.
/// - Loads new objects.
/// - CRUD (including update with spare objects).
/// - Change Notifications.
/// - Persistance.
public class Region {

    // MARK: - Enums
    
    enum RegionError: Error {
        case failedParsingResponse
        case failedParsingObject
    }
    
    // MARK: - Dispatch Queues
    
    /// Serial i/o queue.
    ///
    /// Each subclass with have it's own io queue (the label does not dictate uniqueness).
    let ioQueue = DispatchQueue(label: "io.blockv.sdk.datapool-io",
                                qos: .userInitiated)
    
    /// Concurrent worker queue.
    ///
    /// Use to process mappings and transfromations.
    let workerQueue = DispatchQueue(label: "io.blockv.sdk.datapool-worker",
                                    qos: .userInteractive,
                                    attributes: .concurrent)
    
    /// Concurrent synchronization.
    ///
    /// Used exclusively for object synchronization queue (serial write, concurrent read).
    let syncQueue = DispatchQueue(label: "io.blockv.sdk.object-sync",
                                  qos: .userInitiated,
                                  attributes: .concurrent)
    
    // MARK: - Initialization

    /// Constructor
    required init(descriptor: Any) throws { }

    /// This region plugin's ID.
    class var id: String {
        assertionFailure("subclass-should-override")
        return ""
    }

    /// `true` if this region contains temporary objects which should not be cached to disk, `false` otherwise.
    let noCache = false
    
    private var _objects: [String: DataObject] = [:]

    /// All objects currently in our cache.
    private(set) var objects: [String: DataObject] {
        get { // sync read (concurrent queue)
            return syncQueue.sync { _objects }
        }
        set {
            syncQueue.sync(flags: .barrier) { _objects = newValue }
        }
    }

    /// `true` if data in this region is in sync with the backend.
    public internal(set) var synchronized = false {
        didSet {
            dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

            if synchronized {
                self.emit(.stabalized, userInfo: [:])
            } else {
                self.emit(.destabalized, userInfo: [:])
            }
        }
    }

    /// Contains the current error.
    public internal(set) var error: Error?

    /// An ID which uniquely identifies this region. Used for caching purposes.
    var stateKey: String {
        assertionFailure("subclass-should-override")
        return ""
    }

    /// `true` if this region has been closed.
    public fileprivate(set) var closed = false

    /// Re-synchronizes the region by manually fetching objects from the server again.
    public func forceSynchronize() -> Guarantee<[Any]> {
        
        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

        self.synchronized = false
        return self.synchronize()
    }
    
    public var isSynchronizing: Bool {
        return !(_syncPromise == nil)
    }

    /// Currently executing synchronization promise. `nil` if there is no synchronization underway.
    private var _syncPromise: Guarantee<[Any]>?

    /// Attempts to stablaize the region by querying the backend for all data.
    ///
    /// If the region is already stable, local data is returned.
    ///
    /// - Returns: Promise which resolves when complete.
    @discardableResult
    public func synchronize() -> Guarantee<[Any]> {
        
        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

        self.emit(.synchronizing, userInfo: [:])

        // stop if already running
        if let promise = _syncPromise {
            return promise
        }

        // remove pending error
        self.error = nil
//        self.emit(.updated) //FIXME: This seems an odd place for an `.update` call

        // stop if already in sync
        if synchronized {
            
            Guarantee { resolver in
                workerQueue.async {
                     resolver(self.getAll())
                }
            }

        }

        // ask the subclass to load it's data
        printBV(info: "[DataPool > Region] Starting synchronization for region \(self.stateKey)")

        // load objects
        _syncPromise = self.load().then { ids -> Guarantee<[Any]> in

            /*
             The subclass is expected to call the add method as it finds object, and then, once
             all ids are known, return all the newly added ids.
             Super (this) then calls the remove method on all ids that are no longer present.
             */

            // check if subclass returned an array of IDs
            if let ids = ids {
                self.diffedRemove(ids: ids)
            }
            
            return Guarantee { resolver in
                self.workerQueue.async {
                    resolver(self.getAll())
                    DispatchQueue.main.async {
                        // data is up to date
                        self.synchronized = true
                        self._syncPromise = nil
                        printBV(info: "[DataPool > Region] Region '\(self.stateKey)' is now in sync!")
                    }
                }
            }

        }.recover { err in
            // error handling, notify listeners of an error
            self._syncPromise = nil
            self.error = err
            printBV(error: "[DataPool > Region] Unable to load: " + err.localizedDescription)
            self.emit(.error, userInfo: ["error": err])
            return Guarantee.value([]) //FIXME: Surely a better approach is to return the errors from data pool?
        }

        // return promise
        return _syncPromise!

    }

    /// Start load of remote objects. The promise should resolve once the region is up to date and provides the
    /// set of object ids.
    ///
    /// This function should fetch the _entire_ region.
    ///
    /// - Returns: A promise which will fullsil with an array of object IDs, or `nil`. If an array of object IDs is
    ///   returned, any IDs not in this list should be removed from the region.
    func load() -> Promise<[String]?> {
        return Promise(error: NSError("Subclasses must override Region.load()"))
    }

    /// Stop and destroy this region. Subclasses can override this to do stuff on close.
    public func close() {

        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

        // notify data pool we have closed
        DataPool.removeRegion(region: self)
        // we're closed
        self.closed = true

    }

    /// Checks if the specified query matches our region. This is used to identify if a region request
    /// can be satisfied by this region, or if a new region should be created.
    ///
    /// - Parameters:
    ///   - id: The region plugin ID
    ///   - descriptor: Region-specific filter data
    /// - Returns: True if the described region is this region.
    func matches(id: String, descriptor: Any) -> Bool {
        fatalError("Subclasses muct override Region.matches()")
    }

    /// Add DataObjects to our pool.
    ///
    /// - Parameter objects: The objects to add
    func add(objects: [DataObject]) {
        
        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

        // go through each object
        for obj in objects {

            // skip if no data
            guard let data = obj.data else {
                continue
            }

            // check if exists already
            if let existingObject = self.objects[obj.id] {

                // notify
                self.will(update: existingObject, withFields: data)

                // it exists already, update the object (replace data)
                existingObject.data = data
                existingObject.cached = nil

                self.did(update: existingObject, withFields: data)

            } else {

                // it does not exist, add it
                self.objects[obj.id] = obj

                // notify
                self.did(add: obj)

            }

        }

        // Notify updated
        if objects.count > 0 {
            self.emit(.updated)
            self.save()
        }

    }
    
    enum Source: String {
        case brain
    }

    /// Updates data objects within our pool.
    ///
    /// - Parameter objects: The list of changes to perform to our data objects.        
    func update(objects: [DataObjectUpdateRecord], source: Source? = nil) {
        
        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

        // batch emit events, so if a object is updated multiple times, only one event is sent
        var changedIDs = Set<String>()

        for obj in objects {

            // fetch existing object
            guard let existingObject = self.objects[obj.id] else {
                continue
            }

            // stop if existing object doesn't have the full data
            guard let existingData = existingObject.data else {
                continue
            }

            // notify
            self.will(update: existingObject, withFields: obj.changes)

            // update fields
            existingObject.data = existingData.deepMerged(with: obj.changes)

            // clear cached values
            existingObject.cached = nil

            // notify
            self.did(update: existingObject, withFields: obj.changes)

            // emit event
            changedIDs.insert(obj.id)

        }

        // notify each item that was updated
        for id in changedIDs {
            self.emit(.objectUpdated, userInfo: ["id": id, "source": source?.rawValue ?? ""])
        }

        // notify overall update
        if changedIDs.count > 0 {
            self.emit(.updated)
            self.save()
        }

    }
    
    /// Computes a diff between the supplied ids and the current object ids. Removes the stale ids.
    func diffedRemove(ids: [String]) {
        
        // create a diff of keys to remove
        var keysToRemove: [String] = []
        for id in self.objects.keys {
            
            // check if it's in our list
            if !ids.contains(id) {
                keysToRemove.append(id)
            }
            
        }
        
        // remove objects
        self.remove(ids: keysToRemove)
        
    }

    /// Removes the specified objects from our pool.
    ///
    /// - Parameter ids: The IDs of objects to remove
    func remove(ids: [String]) {
        
        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

        // remove all data objects with the specified IDs
        var didUpdate = false
        for id in ids {

            // remove it
            guard let object = self.objects.removeValue(forKey: id) else {
                continue
            }

            // notify
            didUpdate = true
            self.will(remove: object) //FIXME: Should be didRemove?

        }

        // notify region updated
        if didUpdate {
            self.emit(.updated)
            self.save()
        }

    }

    /// If a region plugin depends on the session data, it may override this method and `self.close()` itself if needed.
    ///
    /// - Parameter info: The new app-specific session info
    func onSessionInfoChanged(info: Any?) {}

    /// If the plugin wants, it can map DataObjects to another type. This takes in a DataObject and returns a new type.
    /// If the plugin returns `nil`, the specified data object will not be returned and will be skipped.
    ///
    /// The default implementation simply returns the DataObject.
    ///
    /// - Parameter object: The DataObject as input
    /// - Returns: The new output object.
    func map(_ object: DataObject) -> Any? {
        return object
    }

//    /// Returns all the objects within this region. Waits until the region is stable first.
//    ///
//    /// - Returns: Array of objects. Check the region-specific map() function to see what types are returned.
//    public func getAllStable() -> Guarantee<[Any]> { //FIXME: This function is no longer needed, rather call `synchronize` directly.
//
//        // synchronize now
//        return self.synchronize()
//
//    }

    /// Returns all the objects within this region. Does NOT wait until the region is stable first.
    public func getAll() -> [Any] {
        
        // create array of all items
        var items: [Any] = []
        for object in objects.values {

            // check for cached concrete type
            if let cached = object.cached {
                items.append(cached)
                continue
            }

            // map to the plugin's intended type
            guard let mapped = self.map(object) else {
                continue
            }

            // cache it
            object.cached = mapped

            // add to list
            items.append(mapped)

        }

        // done
        return items

    }

    /// Returns an object within this region by it's ID. Waits until the region is stable first.
    public func getStable(id: String) -> Guarantee<Any?> {
        
        return self.synchronize().map { _ in
            // get item
            return self.get(id: id)
        }

    }

    /// Returns an object within this region by it's ID.
    public func get(id: String) -> Any? {

        // get object
        guard let object = objects[id] else {
            return nil
        }

        // check for cached concrete type
        if let cached = object.cached {
            return cached
        }

        // map to the plugin's intended type
        guard let mapped = self.map(object) else {
            return nil
        }

        // cache it
        object.cached = mapped

        // done
        return mapped

    }

    /// Load objects from local storage.
    func loadFromCache() -> Promise<Void> {
        
        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))
        
        return Promise { (resolver: Resolver) in
            
            ioQueue.async {
                
                // get filename
                let startTime = Date.timeIntervalSinceReferenceDate
                let filename = self.stateKey.replacingOccurrences(of: ":", with: "_")
                
                // get temporary file location
                let file = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
                    .appendingPathExtension("json")
                
                // read data
                guard let data = try? Data(contentsOf: file) else {
                    printBV(error: ("[DataPool > Region] Unable to read cached data"))
                    resolver.fulfill_()
                    return
                }
                
                // parse JSON
                guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[Any]] else {
                    printBV(error: "[DataPool > Region] Unable to parse cached JSON")
                    resolver.fulfill_()
                    return
                }
                
                // create objects
                let objects = json.map { fields -> DataObject? in
                    
                    // get fields
                    guard let id = fields[0] as? String, let type = fields[1] as? String,
                        let data = fields[2] as? [String: Any] else {
                            return nil
                    }
                    
                    // create DataObject
                    let obj = DataObject()
                    obj.id = id
                    obj.type = type
                    obj.data = data
                    return obj
                    
                }
                
                // Strip out nils
                let cleanObjects = objects.compactMap { $0 }
                
                DispatchQueue.main.async {
                    // add objects
                    self.add(objects: cleanObjects)
                    
                    self.emit(.loadedFromCache)
                }
                
                // done
                let delay = (Date.timeIntervalSinceReferenceDate - startTime) * 1000
                printBV(info: ("[DataPool > Region] Loaded \(cleanObjects.count) from cache in \(Int(delay))ms"))
                resolver.fulfill_()
                
            }
            
        }

    }

    var saveTask: DispatchWorkItem?
    
    /// Saves the region to local storage.
    func save() {
        
        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

        // cancel the pending save task
        if saveTask != nil {
            saveTask?.cancel()
        }

        // create save task
        saveTask = DispatchWorkItem { () -> Void in

            // create data to save
            let startTime = Date.timeIntervalSinceReferenceDate
            let json = self.objects.values.map { return [
                $0.id,
                $0.type,
                $0.data ?? [:]
                ]}

            // convert to JSON
            guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else {
                printBV(error: ("[DataPool > Region] Unable to convert data objects to JSON"))
                return
            }

            // get filename
            let filename = self.stateKey.replacingOccurrences(of: ":", with: "_")

            // get temporary file location
            let file = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
                .appendingPathExtension("json")

            // make sure folder exists
            try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true, attributes: nil)

            // write file
            do {
                try data.write(to: file)
            } catch let err {
                printBV(error: ("[DataPool > Region] Unable to save data to disk: " + err.localizedDescription))
                return
            }

            // done
            let delay = (Date.timeIntervalSinceReferenceDate - startTime) * 1000
            printBV(info: ("[DataPool > Region] Saved \(self.objects.count) objects to disk in \(Int(delay))ms"))

        }

        // Debounce save task
        ioQueue.asyncAfter(deadline: .now() + 5, execute: saveTask!)

    }

    /// Call this to undo an action.
    typealias UndoFunction = () -> Void

    /// Change a field, and return a function which can be called to undo the change.
    ///
    /// - Parameters:
    ///   - id: The object ID
    ///   - keyPath: The key to change
    ///   - value: The new value
    /// - Returns: An undo function
    func preemptiveChange(id: String, keyPath: String, value: Any) -> UndoFunction {
        
        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

        // get object. If it doesn't exist, do nothing and return an undo function which does nothing.
        guard let object = objects[id], object.data != nil else {
            return {}
        }

        // get current value
        let oldValue = object.data![keyPath: KeyPath(keyPath)]

        // notify
        self.will(update: object, keyPath: keyPath, oldValue: oldValue, newValue: value)

        // update to new value
        object.data![keyPath: KeyPath(keyPath)] = value
        object.cached = nil
        self.emit(.objectUpdated, userInfo: ["id": id])
        self.emit(.updated)
        self.save()

        // return undo function
        return {

            // notify
            self.will(update: object, keyPath: keyPath, oldValue: value, newValue: oldValue)

            // update to new value
            object.data![keyPath: KeyPath(keyPath)] = oldValue
            object.cached = nil
            self.emit(.objectUpdated, userInfo: ["id": id])
            self.emit(.updated)
            self.save()

        }

    }

    /// Remove an object, and return an undo function.
    ///
    /// - Parameter id: The object ID to remove
    /// - Returns: An undo function
    func preemptiveRemove(id: String) -> UndoFunction {
        
        dispatchPrecondition(condition: DispatchPredicate.onQueue(.main))

        // remove object
        guard let removedObject = objects.removeValue(forKey: id) else {
            // no object, do nothing
            return {}
        }

        // notify
        self.will(remove: removedObject) //FIXME: should be didRemove
        self.emit(.updated)
        self.save()

        // return undo function
        return {

            // check that a new object wasn't added in the mean time
            guard self.objects[id] == nil else {
                return
            }

            // notify
            self.will(add: removedObject)
            self.add(objects: [removedObject])
            self.save()

        }

    }

    // MARK: - Listener functions, can be overridden by subclasses

    func will(add: DataObject) {}
    func will(update: DataObject, withFields: [String: Any]) {}
    func will(update: DataObject, keyPath: String, oldValue: Any?, newValue: Any?) {}
    func will(remove object: DataObject) {}

    func did(add: DataObject) {}
    func did(update: DataObject, withFields: [String: Any]) {}
//    func did(update: DataObject, keyPath: String, oldValue: Any?, newValue: Any?) {}
//    func did(remove object: DataObject) {}

}
