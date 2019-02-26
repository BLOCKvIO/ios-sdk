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
 IDEAS
 
 -
 
 /// Start an additive load. This should resolve once a partial region is fetched.
 func loadAdditive() -> Promise<[String]?> {
    //
 }
 */

/// An abstract class that manages a complete collection of objects (a.k.a Region).
///
/// Regions are generally "id-complete". That is, the local region should have a complete copy of all remote objects.
///
/// Roles:
/// - In memory store of objects.
/// - Keep track of synchornization state.
/// - Loads new objects.
/// - CRUD (including update with spare objects).
/// - Change Notifications
/// - Persistance (debounced)
///
/// Base class for a Region plugin.
public class Region {

    /// Constructor
    required init(descriptor: Any) throws {

    }

    /// This region plugin's ID.
    class var ID: String {
        return "subclass-should-override"
    }

    /// True if this region contains temporary objects which should not be cached to disk.
    let noCache = false

    /// All objects currently in our cache.
    var objects: [String: DataObject] = [:]

    /// True if data in this region is in sync with the backend.
    public internal(set) var synchronized = false

    /// If there's an error, this contains the current error.
    public internal(set) var error: Error?

    /// An ID which uniquely identifies this region. Used for caching purposes.
    var stateKey: String {
        return "subclass-should-override"
    }

    /// True if this region has been closed.
    public fileprivate(set) var closed = false

    /// Re-synchronizes the region by manually fetching everything from the server again.
    public func forceSynchronize() -> Guarantee<Void> {
        self.synchronized = false
        return self.synchronize()
    }

    /// Currently executing synchronization promise. If `nil` there is no synchronization underway.
    private var _syncPromise: Guarantee<Void>?

    /// This will try to make the region stable by querying the backend for all data.
    ///
    /// - Returns: Promise which resolves when complete.
    @discardableResult
    public func synchronize() -> Guarantee<Void> {

        // Stop if already running
        if let promise = _syncPromise {
            return promise
        }

        // Remove pending error
        self.error = nil
        self.emit(.updated)

        // Stop if already in sync
        if synchronized {
            return Guarantee()
        }

        // Ask the subclass to load it's data
        printBV(info: "[DataPool > Region] Starting synchronization for region \(self.stateKey)")

        // load objects
        _syncPromise = self.load().map { ids -> Void in

            // Check if subclass returned an array of IDs
            if let ids = ids {

                // Create a list of keys to remove
                var keysToRemove: [String] = []
                for id in self.objects.keys {

                    // Check if it's in our list
                    if !ids.contains(id) {
                        keysToRemove.append(id)
                    }

                }

                // Remove objects
                self.remove(ids: keysToRemove)

            }

            // All data is up to date!
            self.synchronized = true
            self._syncPromise = nil
            printBV(error: "[DataPool > Region] Region '\(self.stateKey)' is now in sync!")

        }.recover { err in
            // Error handling, notify listeners of an error
            self._syncPromise = nil
            self.error = err
            printBV(error: "[DataPool > Region] Unable to load: " + err.localizedDescription)
            self.emit(.error, userInfo: ["error": err])
        }

//        }.catch { err -> Void in
//
//            // Error handling, notify listeners of an error
//            self._syncPromise = nil
//            self.error = err
//            printBV(error: "[DataPool > Region] Unable to load: " + err.localizedDescription)
//            self.emit(.error, userInfo: ["error": err])
//
//        }

        // Return promise
        return _syncPromise!

    }

    /// Start initial load. The promise sohuld resolve once the region is up to date and provide the set of object ids.
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

        // Notify data pool we have closed
        DataPool.removeRegion(region: self)

        // We're closed
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

    /// Add DataObjects to our pool
    ///
    /// - Parameter objects: The objects to add
    func add(objects: [DataObject]) {

        // Go through each object
        for obj in objects {

            // Skip if no data
            guard let data = obj.data else {
                continue
            }

            // Check if exists already
            if let existingObject = self.objects[obj.id] {

                // Notify
                self.will(update: existingObject, withFields: data)

                // It exists already, update the object (replace data)
                existingObject.data = data
                existingObject.cached = nil

            } else {

                // Notify
                self.will(add: obj)

                // It does not exist, add it
                self.objects[obj.id] = obj

            }

            // Emit event
            self.emit(.objectUpdated, userInfo: ["id": obj.id])

        }

        // Notify updated
        if objects.count > 0 {
            self.emit(.updated)
            self.save()
        }

    }

    /// Updates data objects within our pool.
    ///
    /// - Parameter objects: The list of changes to perform to our data objects.
    func update(objects: [DataObjectUpdateRecord]) {

        // Batch emit events, so if a object is updated multiple times, only one event is sent
        var changedIDs = Set<String>()

        for obj in objects {

            // Fetch existing object
            guard let existingObject = self.objects[obj.id] else {
                continue

                // This is an odd case. A spare update is being skipped because the object was not found.
                // This indicates that something is wrong with the synchronization.
                //TODO: Re-synchronize here?
            }

            // Stop if existing object doesn't have the full data
            guard let existingData = existingObject.data else {
                continue

                // This is also an odd case. What would cause the existing object to not have data?
            }

            // Notify
            self.will(update: existingObject, withFields: obj.changes)

            // Update fields
            existingObject.data = existingData.deepMerged(with: obj.changes)

            // Clear cached values
            existingObject.cached = nil

            // Emit event
            changedIDs.insert(obj.id)

        }

        // Notify each item that was updated
        for id in changedIDs {
            self.emit(.objectUpdated, userInfo: ["id": id])
        }

        // Notify overall update
        if changedIDs.count > 0 {
            self.emit(.updated)
            self.save()
        }

    }

    /// Removes the specified objects from our pool.
    ///
    /// - Parameter ids: The IDs of objects to remove
    func remove(ids: [String]) {

        // Remove all data objects with the specified IDs
        var didUpdate = false
        for id in ids {

            // Remove it
            guard let object = self.objects.removeValue(forKey: id)else {
                continue
            }

            // Notify
            didUpdate = true
            self.will(remove: object)

        }

        // Notify updated
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

    /// Returns all the objects within this region. Waits until the region is stable first.
    ///
    /// - Returns: Array of objects. Check the region-specific map() function to see what types are returned.
    public func getAllStable() -> Guarantee<[Any]> {

        // Synchronize now
        return self.synchronize().map({
            return self.getAll()
        })

    }

    /// Returns all the objects within this region. Does NOT wait until the region is stable first.
    public func getAll() -> [Any] {

        // Create array of all items
        var items: [Any] = []
        for object in objects.values {

            // Check for cached concrete type
            if let cached = object.cached {
                items.append(cached)
                continue
            }

            // Map to the plugin's intended type
            guard let mapped = self.map(object) else {
                continue
            }

            // Cache it
            object.cached = mapped

            // Add to list
            items.append(mapped)

        }

        // Done
        return items

    }

    /// Returns an object within this region by it's ID. Waits until the region is stable first.
    public func getStable(id: String) -> Guarantee<Any?> {

        // Synchronize now
        return self.synchronize().map {
            // Get item
            return self.get(id: id)
        }

    }

    /// Returns an object within this region by it's ID.
    public func get(id: String) -> Any? {

        // Get object
        guard let object = objects[id] else {
            return nil
        }

        // Check for cached concrete type
        if let cached = object.cached {
            return cached
        }

        // Map to the plugin's intended type
        guard let mapped = self.map(object) else {
            return nil
        }

        // Cache it
        object.cached = mapped

        // Done
        return mapped

    }

    /// Load objects from local storage
    func loadFromCache() -> Promise<Void> {

        // Get filename
        let startTime = Date.timeIntervalSinceReferenceDate
        let filename = self.stateKey.replacingOccurrences(of: ":", with: "_")

        // Get temporary file location
        let file = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
            .appendingPathExtension("json")

        // Read data
        guard let data = try? Data(contentsOf: file) else {
            printBV(error: ("[DataPool > Region] Unable to read cached data"))
            return Promise()
        }

        // Parse JSON
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[Any]] else {
            printBV(error: "[DataPool > Region] Unable to parse cached JSON")
            return Promise()
        }

        // Create objects
        let objects = json.map { fields -> DataObject? in

            // Get fields
            guard let id = fields[0] as? String, let type = fields[1] as? String,
                let data = fields[2] as? [String: Any] else {
                return nil
            }

            // Create DataObject
            let obj = DataObject()
            obj.id = id
            obj.type = type
            obj.data = data
            return obj

        }

        // Strip out nils
        let cleanObjects = objects.compactMap { $0 }

        // Add objects
        self.add(objects: cleanObjects)

        // Done
        let delay = (Date.timeIntervalSinceReferenceDate - startTime) * 1000
        printBV(info: ("[DataPool > Region] Loaded \(cleanObjects.count) from cache in \(Int(delay))ms"))
        return Promise()

    }

    var saveTask: DispatchWorkItem?

    /// Saves the region to local storage.
    func save() {

        // TODO: Implement better caching via Realm or something

        // Cancel the pending save task
        if saveTask != nil {
            saveTask?.cancel()
        }

        // Create save task
        saveTask = DispatchWorkItem { () -> Void in

            // Create data to save
            let startTime = Date.timeIntervalSinceReferenceDate
            let json = self.objects.values.map { return [
                $0.id,
                $0.type,
                $0.data ?? [:]
                ]}

            // Convert to JSON
            guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else {
                printBV(error: ("[DataPool > Region] Unable to convert data objects to JSON"))
                return
            }

            // Get filename
            let filename = self.stateKey.replacingOccurrences(of: ":", with: "_")

            // Get temporary file location
            let file = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
                .appendingPathExtension("json")

            // Make sure folder exists
            try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true, attributes: nil)

            // Write file
            do {
                try data.write(to: file)
            } catch let err {
                printBV(error: ("[DataPool > Region] Unable to save data to disk: " + err.localizedDescription))
                return
            }

            // Done
            let delay = (Date.timeIntervalSinceReferenceDate - startTime) * 1000
            printBV(info: ("[DataPool > Region] Saved \(self.objects.count) items to disk in \(Int(delay))ms"))

        }

        // Debounce save task
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: saveTask!)

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

        // Get object. If it doesn't exist, do nothing and return an undo function which does nothing.
        guard let object = objects[id], object.data != nil else {
            return {}
        }

        // Get current value
        let oldValue = object.data![keyPath: KeyPath(keyPath)]

        // Notify
        self.will(update: object, keyPath: keyPath, oldValue: oldValue, newValue: value)

        // Update to new value
        object.data![keyPath: KeyPath(keyPath)] = value
        object.cached = nil
        self.emit(.objectUpdated, userInfo: ["id": id])
        self.emit(.updated)
        self.save()

        // Return undo function
        return {

            // Notify
            self.will(update: object, keyPath: keyPath, oldValue: value, newValue: oldValue)

            // Update to new value
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

        // Remove object
        guard let removedObject = objects.removeValue(forKey: id) else {
            // No object, do nothing
            return {}
        }

        // Notify
        self.will(remove: removedObject)
        self.emit(.updated)
        self.save()

        // Return undo function
        return {

            // Check that a new object wasn't added in the mean time
            guard self.objects[id] == nil else {
                return
            }

            // Notify
            self.will(add: removedObject)
            self.add(objects: [removedObject])
            self.save()

        }

    }

    /// Listener functions, can be overridden by subclasses
    func will(add: DataObject) {}
    func will(update: DataObject, withFields: [String: Any]) {}
    func will(update: DataObject, keyPath: String, oldValue: Any?, newValue: Any?) {}
    func will(remove object: DataObject) {}

}
