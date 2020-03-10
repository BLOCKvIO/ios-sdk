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
import PromiseKit

enum SyncError: Error {
    case failedParsingResponse
    case failedParsingObject
}

/*
 VatomDataProvider
 
 # Learnings
 
 - JSON to Struct to Core Data is how Apple does it.
 - This means I can get rid of the descriptable stuff.
 
 # TODO
 
 - List children - a predicate lookup would work, but if the vatom enity referenced itself, then the lookup would be quick
 the drawback it the assciative step where parents are linked to children, however, then would be quick once the vatom's
 - I've added a template entity. This solves the associative step (since look up on the template
 
 # Ideas
 
 - Recursing the inventory could be wrapped in a dispatch work item, that way it can be submitted to a queue and be
 guaranteed to complete before any other changes are applied. Well, things are a bit more tricky than that. If a ws
 state_update arrives during an inventory sync, the state update can be process *if* the vatom in question has already
 been processed.
 
 ## Relationship Association
 
 There are two assocaition processed needed:
 1. Faces & Actions must have their relationship with vatoms configured
 -> This can be done in-batch
 2. Vatom parent-child relationships must be setup.
 -> This cannot be done in-batch. The *entire* inventory must be local for these relationships to be configured.
 
 'In-batch' means the association can be completed entirelty with a single batch/page of the inventory. Otherwise,
 more information is needed.
 
 Running association 2. has some challenges because the number of objects may be large.
 
 Options:
 
 1. Performing a fetch request on all vatoms (after all vatoms have been saved) and then looping through setting the relationships is the easiest.
 > Drawback: may tip the app over the memory limit. It also defets the fetch-and-save process.
 
 2. Performing parent assocaitions for all vatoms within a batch before saving.
 > This is fast because all objects are in the context tier.
 > Drawback: parent vatom may be in other batches and so will be missed.
 Then finally, fetch all non-parented vatom and run the association.
 > Slightly faster becuase some vatoms will already have a parent association.
 
 3. Perform the association later, and only when needed.
 
 
 To avoid an expensive round trip to the database, it would be nice if these object were still in the context (but this means high memory overhead).
 What about if they are kept in the row cache?
 Another option is to run a process that fetches all the objects as faults, but this won't work becuase the `id` property is required, and this will fault in all properties.
 
 
 */

/*
 ## Image Policy Face
 - https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/FrequentlyAskedQuestions.html
 - The keyPathsForValuesAffectingValueForKey
 ## Parent-child relationships
 - Inorder to make a parent child relationship between vatoms, all vatoms would need to be in memory in one context.
 This is not good for performace. The importer specifically performs batches and saves. This would have to be reworked
 For now, parent child will have to be fetch requests.
 Alternatively, a 'linking' step can be run once all data is imported to create the relationship. This would have to
 be done on the serial sync queue.
 
 
 ## Association
 - I think there should be an association step after all the vatoms have been downloaded.
 */

/*
 Debugging
 https://stackoverflow.com/questions/8337635/nsmanagedobjectcontext-exception-breakpoint-stops-at-save-method-but-no-log-c
 */

/// Taksed with doing a 'full sync' downloading all vatoms.
final class VatomDownloader: ChangeProcessor {
    
    // MARK: - Properties
    
    /// Page size parameter sent to the server.
    private let pageSize = 100
    /// Upper bound to prevent infinite recursion.
    private let maxReasonablePages = 50
    /// Number of batch iterations.
    private var iteration = 0
    /// Number of processed pages.
    private var proccessedPageCount = 0
    /// Cummulative object ids.
    fileprivate var cummulativeIds: [String] = []
    
    // MARK: - Protocol
    
    /*
     This function will be called only once when the sync coordinator is initialized.
     So might be a decent place to start up the web socket?
     */
    
    func setup(for context: ChangeProcessorContext) {
        //        context.remote.setupMoodSubscription()
    }
    
    /*
     Called to notify about changes to the local database (which may have happend from the main or sync context)
     */
    
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext) {
        // no-op
    }
    
    /*
     Called to notify about changes in the cloud.
     Does this fall under the web socket?
     How should this be handled?
     */
    
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        var creates: [VatomModel] = []
        var deletionIDs: [RemoteRecordID] = []
        for change in changes {
            switch change {
                
                /*
                 Do I need to support both packaged [VatomModel] and UnpackedModel? Essentially it come down to where
                 the association/packaging step happens..
                 */
                
            case .insert(let model) where model is [VatomModel]:
                print("[VatomDownloader]", #function, "insert packed vatom model")
                
                
            case .insert(let model) where model is UnpackedModel:
                print("[VatomDownloader]", #function, "insert unpacked")
                //TODO: insert new vatom
                
            case .partialUpdate(let update):
                print("[VatomDownloader]", #function, "update")
                //TODO: merge is state update
                
            case .delete(let id):
                print("[VatomDownloader]", #function, "delete")
                deletionIDs.append(id)
                
            default: fatalError("change reason not implemented")
            }
        }
        
        //        insert(creates, into: context.context)
        deleteVatoms(with: deletionIDs, in: context.context)
        context.delayedSaveOrRollback()
        completion()
    }
    
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
        //        context.remote.fetchLatestMoods { remoteMoods in
        //            context.perform { // does this swop back onto the correct queue?
        //                self.insert(remoteMoods, into: context.context)
        //                context.delayedSaveOrRollback()
        //            }
        //        }
        
        /*
         This method is called with a sync context's perform block, so it will run on the private serial queue.
         */
        
//        self.associateParentVatoms(in: context)
        
        context.coordinatorGroup.enter()
        self.fetchAllBatched(in: context).ensure {

            context.perform {
                self.associateParentVatoms(in: context)//.ensure { //FIXME: This function is not a promise, will it ever be?
                    context.coordinatorGroup.leave()
                //}
            }
            
        }
        
    }
    
    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>? {
        return nil
    }
    
}

extension VatomDownloader {
    
    fileprivate func deleteVatoms(with ids: [RemoteRecordID], in context: NSManagedObjectContext) {
        guard !ids.isEmpty else { return }
        let vatoms = VatomCD.fetch(in: context) { (request) -> () in
            request.predicate = VatomCD.predicateForRemoteIdentifiers(ids)
            request.returnsObjectsAsFaults = false
        }
        vatoms.forEach { $0.markForLocalDeletion() }
    }
    
    // inserts new remote vatoms
    //    fileprivate func insert(_ vatomModels: [VatomModel], into context: NSManagedObjectContext) {
    //
    //        /*
    //         - Should this be treated as an insert or update, or both?
    //         - Should I use the sync number on Vatom?
    //         */
    //
    //        // create materialized dictionary of existing vatoms
    //        let existingVatoms = { () -> [RemoteRecordID: VatomCD] in
    //            let ids = vatomModels.map { $0.id }
    //            let vatoms = VatomCD.fetch(in: context) { request in
    //                request.predicate = VatomCD.predicateForRemoteIdentifiers(ids)
    //                request.returnsObjectsAsFaults = false
    //            }
    //            var result: [RemoteRecordID: VatomCD] = [:]
    //            for vatom in vatoms {
    //                result[vatom.id] = vatom
    //            }
    //            return result
    //        }
    //
    //        // insert new objects
    //        for vatom in vatomModels {
    //            if existingVatoms[vatom.id] == nil {
    //
    //            }
    //        }
    //
    //    }
    
    // inserts new remote vatoms
    //    fileprivate func insert(_ unpackedModel: UnpackedModel, into context: NSManagedObjectContext) {
    //
    //        let existingVatoms = { () -> [RemoteRecordID: VatomCD] in
    //            let ids = unpackedModel.vatoms.map { $0.id }
    //            let vatoms = VatomCD.fetch(in: context) { request in
    //                // fetch all objects with the ids (i.e. they have already been pushed to the backend)
    //                // with vatoms, this is always the case, none are created locally
    //                request.predicate = VatomCD.predicateForRemoteIdentifiers(ids)
    //                request.returnsObjectsAsFaults = false
    //            }
    //            var result: [RemoteRecordID: VatomCD] = [:]
    //            for vatom in vatoms {
    //                result[vatom.id] = vatom
    //            }
    //            return result
    //        }()
    //
    //        // insert new remote vatoms
    //        for remoteMood in remoteMoods {
    //            guard let id = remoteMood.id else { continue }
    //            guard existingVatoms[id] == nil else { continue } // skip objects that already have an id (i.e. they have already been pushed to the backend)
    //            let _ = remoteMood.insert(into: context) // insert new objects (since there are no objects with the id yet)
    //        }
    //    }
    
    /*
     Moods work differnetly.
     1. They can be created locally (without a remote id).
     2. They cannot be updated once created.
     Beacuse of this, this code only handles inserting of new object. That is objects that are present on the server
     but not yet on the client. That local object (without ids) have not yet been pushed to the server, so they are
     ignored.
     
     Vatoms work differently. They need to be update attribute-wise.
     - Also, since the payload is [String: Any], it's not as nice to work with.
     
     How do I do an insert or update?
     */
    
}

extension VatomDownloader {
    
    /*
     # Goals
     
     The way we sync stays the same:
     
     1. Full vatom sync (v1)
     2. Partial vatom sync (v2) + Face/Action Change Sync
     
     Option 2 is preferred.
     If option 2 fails, option 1 must be the fallback.
     
     Q: Should these be two separate change processors, or just within one change processor?
     
     
     Fetch-and-save
     - Fetch each page and save it to the database. This will avoid a high memory overhead.
     Q: How will this work with the association step?
     
     1. Recurse the entire inventory.
     > Pause the websocket (so the whole recursion must be wrapped in a perform group). This will ensure the socket messages are processed *after* the full sync.
     2.
     */
    
    /// Partial sync (v2 - vatom sync numbers)
    ///
    /// Only fetch what changes using vatom sync number and face/action tokens.
    func partialSync(in context: ChangeProcessorContext) {
        
        
        
    }
    
    func fullSync(in context: ChangeProcessorContext) {
        
        /*
         //         the BIG ISSUE is that the sync coordintor has a sync context which uses a private serial queue (which we can't 'get hold' of, but can dispatch onto).
         //
         //         so, the remote interface will execute the request and dispatch the response onto a queue for response parsing (likely concurrent)
         //         the blockv client will then dispatch the completion handler onto the main queue, or, the queue specified in the request
         //
         //         my worry is thread explosion, or at the least, bad performance becuase of queue hopping
         //         now, currently there is no way to know the sync queue from a change processor
         //         Q: so what queue to I pass to the request below?
         //         Q: if I use promises, the handler is dispatched on the main queue, but that's no good. Promises take a queue argument, but I don't know the current queue (i.e. the private sync queue)
         //
         //         Options:
         //         1. Pass down the sync queue (is that even possible)?
         //         2. Just accept the queue hopping.
         //
         //         */
        
        /*
         Q: Where does the top level log for sync lie?
         - Check inventory hash
         - Check faces and actions
         - Check vatom sync numbers
         -
         */
        
        // 1. fetch inventory
        
        
        
        // 2. make parent associations
        
        /*
         1. Fetch all vatoms with a parent id (not ".") and where parent relationship is nil
         2. Walk over all vatoms and configure the parent relationship
         */
        
    }
    
    /// Fetches all object in the inventory.
    fileprivate func fetchAllBatched(maxConcurrent: Int = 4, in context: ChangeProcessorContext) -> Promise<Void> {
        
        let intialRange: CountableClosedRange<Int> = 1...maxConcurrent
        return fetchRange(intialRange, in: context)
        
    }
    
    private func fetchRange(_ range: CountableClosedRange<Int>, in context: ChangeProcessorContext) -> Promise<Void> {
        
        iteration += 1
        os_log("[VatomDownloader] Full Sync: Fetcing Range: %@, Iteration: %d", log: .dataPool, type: .debug,
               range.debugDescription, iteration)
        
        var promises: [Promise<Void>] = []
        
        // tracking flag
        var shouldRecurse = true
        
        for page in range {
            
            let promise = context.remote.getInventory(id: "*", page: page, limit: pageSize, queue: .main).then { unpackedModel -> Promise<Void> in
                
                return Promise { (resolver: Resolver) in
                    
                    // hop onto the sync queue and import
                    context.perform {
                        try? self.importOnePackage(unpackedModel: unpackedModel, context: context) //FIXME: Handle throw
                    }
                    
                    if (unpackedModel.vatoms.isEmpty) || (self.proccessedPageCount > self.maxReasonablePages) {
                        shouldRecurse = false
                    }
                    
                    // increment page count
                    self.proccessedPageCount += 1
                    
                    return resolver.fulfill(())
                    
                }
                
            }
            
            promises.append(promise)
            
        }
        
        // when the batch of requests resolves, execute the next batch
        return when(resolved: promises).then { _ -> Promise<Void> in
            
            // check stopping condition
            if shouldRecurse {
                
                // create the next range (with equal width)
                let nextLower = range.upperBound.advanced(by: 1)
                let nextUpper = range.upperBound.advanced(by: range.upperBound)
                let nextRange: CountableClosedRange<Int> = nextLower...nextUpper
                
                return self.fetchRange(nextRange, in: context)
                
            } else {
                os_log("[VatomDownloader] Full Sync: Stopped on page %d", log: .dataPool, type: .debug,
                       self.proccessedPageCount)
                self.iteration = 0
                self.proccessedPageCount = 0
                //FIXME: Address this
                //                self.lastFaceActionFetch = Date().timeIntervalSince1970InMilliseconds
                return Promise.value(())
            }
            
        }
        
    }
    
    
    /// Creates and assocaited managed objects
    ///
    /// Logic
    /// 1. Creates a managed object for all vatoms, faces, and actions.
    /// 2. Associated faces and actions with vatoms.
    /// 3. *Partially* associates child vatoms with their parent.
    /// 4. Saves the managed objects to the store.
    ///
    ///- important
    /// The caller must ensure this method is properly thread confined when calling it since it creates and operates on managed objects.
    private func importOnePackage(unpackedModel: UnpackedModel, context: ChangeProcessorContext) throws -> Void {
        
        // import faces
        // import actions
        // import vatoms
        // associate faces and actions
        // associated parents (partially)
        
        /*
         As we create/insert the objects into the managed object context, we get an array of references. This
         can be used for the association step.
         */
        
        // 1. create a new record for each quake in the batch.
        var faceObjects: Set<FaceCD> = []
        for model in unpackedModel.faces {
            do {
                let face = try FaceCD.insert(with: model, in: context.context)
                faceObjects.insert(face)
            } catch {
                //TODO: In EarthQuake they delete the vatom if the update with data fails. This may be required
                // here if the new vatoms data can't be added.
                print(error.localizedDescription)
            }
        }
        
        var actionObjects: Set<ActionCD> = []
        for model in unpackedModel.actions {
            do {
                let action = try ActionCD.insert(with: model, in: context.context)
                actionObjects.insert(action)
            } catch {
                //TODO: In EarthQuake they delete the vatom if the update with data fails. This may be required
                // here if the new vatoms data can't be added.
                print(error.localizedDescription)
            }
        }
        
        var vatomObjects: Set<VatomCD> = []
        for model in unpackedModel.vatoms {
            do {
                let vatom = try VatomCD.insert(with: model, in: context.context)
                vatomObjects.insert(vatom)
            } catch {
                //TODO: In EarthQuake they delete the vatom if the update with data fails. This may be required
                // here if the new vatoms data can't be added.
                print(error.localizedDescription)
            }
        }
        
        // X. Associate tags
//        let currentTags = TagCD.fetch(in: context.context) {
//            $0.predicate = TagCD.defaultPredicate
//        }
        
        for vatom in vatomObjects {
            // 2. Association (faces and actions)
            let associatedFaces = faceObjects.filter { $0.templateID == vatom.templateID }
            vatom.faces = associatedFaces
            let associatedActions = actionObjects.filter { $0.templateID == vatom.templateID }
            vatom.actions = associatedActions
            
            // 3. Partial Association (set parents if available in this package)
            if vatom.parentID != "." {
                vatom.parent = vatomObjects.first(where: { $0.id == vatom.parentID } )
            }
            
            // 4. Tags
            //for tag in vatom.tags
            
            /*
             Uniqueness contraints?
             - This will prevent tags with the same name being inserted into the database.
             But, if 10 vatoms have the same tag name, and all ten are added to the tags relationship, then what happens when the tags get saved?
             Does all the relationships get merged? So one tag to ten vatoms.
             Or, does the first tag to get saved win, so only has one vatom relationship
             */
            
        }
    
        // 4. save all insertions and deletions from the context to the store.
        
        if context.context.hasChanges {
            do {
                //FIXME: book does saveOrRollback
                
                /*
                 Also, the remote state should trump the local state. Since there will be uniqieness constrain
                 "Uniqueness constraint conflicts are reported and resolved via tha same mechanism as optimistic
                 locking conflicts: the context's merge policy.
                 
                 "The save operation will throw an error if you don't set a merge policy on the saving context.
                 */
                
                /*
                 Issues:
                 1. saveOrRollback is at odds with try catch, that function tries to hide the error.
                 2. purposely not using delayedSaveOrRollback, becuase we want all work to execute within the outer perform block
                 */
                
                //FIXME: The Objective-C exception is being pumped out here. Might be related to actions and faces?
                
                try context.context.save() // saveOrRollback()
                print("TaskContext - Save")
            } catch {
                //FIXME: How to handle the error? Maybe like saveOrRollback?
                print("Error: \(error)\nCould not save Core Data context.")
            }
            // reset the context to free the cache and lower the memory footprint.
            context.context.reset()
        }
        
    }
    
    /*
     The goal is to associated all parent vatoms
     */
    func associateParentVatoms(in context: ChangeProcessorContext) {
        
        // Q: Does this function need to be asynchronous
        
        // This process may need to be chunked
        
        // 1. Fetch all vatoms in that have a parent id that's not "." and their parent relationship is not set
        // 2. Find child vatoms
        // 3. Associtate
        // 4. Save
        
        let request = VatomCD.fetchRequest()
        let unassociatedParentPredicate = NSPredicate(format: "parentID != %@", ".") // && (parent == nil || parent.@count = 0)
        request.predicate = unassociatedParentPredicate
      
        //TODO: Why can't I use this? findOrFetch doesn't seem to take the right values.
//        request.returnsObjectsAsFaults = false
//        request.propertiesToFetch = ["parentID", "parent"] // saves memory
//        let results = try! context.context.fetch(request) as! [VatomCD]
        
//        let vatoms = VatomCD.findOrFetch(in: context.context, matching: unassociatedParentPredicate)
//        print(vatoms)
//
//        // OR
//
//        // this version is not as efficient as the `findOrFetch` method, becuase hits the sql teir everytime.
//        let vatoms2 = VatomCD.fetch(in: context.context) { request in
//            request.predicate = unassociatedParentPredicate
//            request.propertiesToFetch = ["parentID", "parent"]
//        }
        
        /*
         ## Concern
         
         This is going to pull all vatoms into memory. I've tried to offset it with `propertiesToFetch`.
         For large inventories this shoud be batches somehow. To keep the memory footprint low?
         */
        
        // fetch all vatoms
        let allVatoms = VatomCD.fetch(in: context.context) { request in
            request.propertiesToFetch = ["id", "parentID", "parent"]
        }
        
        allVatoms.forEach { print($0.parent) }
        
        // find parentless vatoms
        let parentlessVatoms = allVatoms.filter { $0.parentID != "." && $0.parent == nil }
        
        for unparentedVatom in parentlessVatoms {
            print("[VatomDownloader] Setting vatom \(unparentedVatom.id) parent to: \(unparentedVatom.parentID)")
            let parent = allVatoms.first(where: { $0.id == unparentedVatom.parentID })!
            unparentedVatom.parent = parent
        }
        
        // the changes are in the context, so just ensure they get persisted at some point
        context.delayedSaveOrRollback()
        
        allVatoms.forEach { print($0.parent) }
        
        print("done")
    }
    
}

/*
 Extensions which convert the callback interface into a promise interface.
 */

extension RemoteInterface {
    
    //FIXME: Queues work differently in Promises. Is the `queue` argument valid in this case?
    
    /*
     Promises pose a problem, their blocks are dispatched onto the main queue. This means a lot of queue hopping.
     To get the block to run on the sync queue,
     
     Won't this 'queue hop' off the sync context's queue? How do I get it back on? Do I need to create another private
     queue on which to process all the data? Because it can't be done on the main thread.
     */
    
    func getInventory(id: String, page: Int, limit: Int, queue: DispatchQueue) -> Promise<UnpackedModel> {
        
        Promise.init { resolver in
            self.getInventory(id: id, page: page, limit: limit, queue: queue) { result in
                switch result {
                case .success(let x):
                    resolver.fulfill(x)
                case .failure(let error):
                    resolver.reject(error)
                }
            }
        }
        
    }
    
}


// MARK: - Old

//extension VatomDownloader {
    
    //    private func importPackage(vatoms: [[String: Any]], faces: [[String: Any]], actions: [[String: Any]], in context: ChangeProcessorContext) throws {
    //
    //        guard !vatoms.isEmpty else { return }
    //
    //        /*
    //         Quakes sets the context's undoManager to nil here (for macOS) since it improves import performance.
    //         Something to look at.
    //         */
    //
    //        /*
    //         Memory optimization: The package is processed in chucks of 256 (or fewer). This safeguards against the page
    //         size chagning.
    //         */
    //        let batchSize = 256
    //        // chunk to reduce memory footprint
    //        let facesChunked = faces.eachSlice(batchSize)
    //        let actionsChunked = actions.eachSlice(batchSize)
    //        let vatomsChunked = vatoms.eachSlice(batchSize)
    //
    //        /*
    //         Since the context is saved after every batch is processed, it is important that faces and actions are processed
    //         before the vatoms. This ensures that consumers of vatoms will see a 'complete' vatom.
    //         */
    //
    //        print(vatomsChunked.count)
    //
    //        facesChunked.forEach {
    //            importOneBatch($0, objectType: FaceCD.self, taskContext: context.context)
    //        }
    //
    //        //        actionsChunked.forEach {
    //        //            importOneBatch($0, objectType: ActionCD.self, taskContext: taskContext)
    //        //        }
    //
    //        vatomsChunked.forEach {
    //            importOneBatch($0, objectType: VatomCD.self, taskContext: context.context)
    //        }
    //
    //    }
    //
    //
    //    /**
    //     Imports one batch of vatoms, creating managed objects from the new data,
    //     and saving them to the persistent store, on a private queue. After saving,
    //     resets the context to clean up the cache and lower the memory footprint.
    //
    //     NSManagedObjectContext.performAndWait doesn't rethrow so this function
    //     catches throws within the closure and uses a return value to indicate
    //     whether the import is successful.
    //     */
    //    private func importOneBatch(_ batch: [[String: Any]], objectType: JSONUpdatable.Type, taskContext: NSManagedObjectContext) -> Bool {
    //
    //        var success = false
    //
    //        //FIXME: I presume perform and wait is ment for a serial queue! That way the batches are processed in order.
    //        //FIXME: Will `performAndWait` block my request's serial processing queue? if so, might be best to get another.
    //
    //        /*
    //         Some articles dont' recommend using performAndWait, I guess it is used here to process each batch in order.
    //         Is this needed for vatoms? Yes I think so, it's the memory aspect that is important, making sure the
    //         context is reset each time.
    //
    //         This means I need to check that
    //         */
    //
    //        // taskContext.performAndWait runs on the URLSession's delegate queue
    //        // so it won’t block the main thread.
    //        taskContext.performAndWait {
    //
    //            // 1. create a new record for each quake in the batch.
    //            for descriptor in batch {
    //
    //                do {
    //                    try objectType.update(into: taskContext, with: descriptor)
    //                } catch {
    //                    //TODO: In EarthQuake they delete the vatom if the update with data fails. This may be required
    //                    // here if the new vatoms data can't be added.
    //                    print(error.localizedDescription)
    //                }
    //
    //            }
    //
    //            //TODO: Old earthquake did comparisons and batch deletions here but the new code did not, why?
    //            // Surely those vatoms no longer present will have to be deleted?
    //
    //            // 2. save all insertions and deletions from the context to the store.
    //            if taskContext.hasChanges {
    //                do {
    //                    try taskContext.save() //FIXME: book does saveOrRollback
    //                } catch {
    //                    print("Error: \(error)\nCould not save Core Data context.")
    //                    return
    //                }
    //                // Reset the taskContext to free the cache and lower the memory footprint.
    //                taskContext.reset()
    //            }
    //
    //            success = true
    //        }
    //        return success
    //
    //    }
    
//}
