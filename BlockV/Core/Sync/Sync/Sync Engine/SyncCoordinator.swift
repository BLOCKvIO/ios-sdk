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

/*
 Asynchronous Platform Implications:
 1. Web sockets must be queued while inventory is sync'd
 2. Web sockets must be queued while added vatom is fetched (until server provides full payload on inventory ws event).
 3.
 
 If the web socket's work is performed on the syncGroup, then it should be synchronized correctly, right?
 */

/*
 # Synchronization
 
 It is very important to understand that there are a few synchronization merthods happening.
 
 Regarding the sync context in particular there are two mechanisms:
 1. The private serial queue which backs the sync context.
 2. DispatchGroup to keep track of work that 
 
 # Challenge
- Need to submit blocks to the sync queue, to get processed on that queue (of course), while preventing other blocks from running on that queue
- I don't have access to the private queue of the sync context. It is hidden/abstracted away?
 
 # Idea
 
 I am exploring 2 solutions:
 
 (likely not a good solution)
 1. Try an perform a single block on the sync queue that containts the entire full sync.
 > This way, all web socket messages will be forced to run *after* this block has completed.
 
 Drawbacks:
 - Parsing of the reponse should/must be done on alamofire's internal concurrent queue. It's too inefficient to do it on the sync serial queue.
   How then do I get back onto the sync queue once the response is parsed?
 
 2. Force the websocket to only process its events when the sync group is empty.
 > If I add a method `performOnEmpty` which will only fire the web socket messages when the sync group's notify gets called.
 > The full sync would then have to enter, and the only exit the group once the sync is complete.
 Q: How will this affect
 
 I think 2 is the way to go. But, to ensure the group is entered when the full sync starts, and then only exited once all done, the sync-cooridnate will have to manually enter and exit the group.
 

 ### Idea
 
 1. Create a change processor 'VatomChangeHanlder'. It will deal with all changes to vatoms
 
 
 ### What change processors do I need?
 
 1. VatomDownloader (full sync & partial sync)
 2. VatomRemover
 3. VatomUploaded - not needed yet
 4. VatomChangeProcessor - deal with local updates, and state_update over websocket
 5. FaceActionHanler? Should this be separate from the other ones?
 
 */

/// This is the central class that coordinates synchronization with the remote API and Web socket.
final class SyncCoordinator {

    internal typealias ApplicationDidBecomeActive = () -> ()
    
    let viewContext: NSManagedObjectContext
    let syncContext: NSManagedObjectContext
    let syncGroup: DispatchGroup = DispatchGroup()
    
    /*
     When the coordinator group is empty (you'll know by adding a closure to the notify function), then the system is
     not synchronising.
     
     For example, when the inventorty is syncing, the group will have a token, once sync is complete, the notify blocks
     will be called.
     
     This allows the web socket messages to be queue (as notify blocks) until the sync process has completed. Thus, the
     change processors can be invoked in a safe way knowing that they won't have race issues with the inventory sync.
     
     ## Inventory Race Conditions
     
     Logic:
     1. The web socket will perpeptually emit changes.
     2. Those changes must be merged into the local inventory.
     3. Those changes are only valid is the local inventory is in sync with the remote.
     
     Example of a race condition:
     0. Client is out of sync and has only vatom A, B and C.
     1. Client begins recursing inventory endpoint to fetch 'all' vatoms. This happens between t_s and t_f.
     2. Somewhere between t_s and t_f, say t_x, a web socket message is emitted to remove vatom
     3.
     
     > Now I'm confussed.
     
     What I do know, becuase there is an association step at the end (after all page recursing). It does not make sense
     to do partial updates (e.g. parent id change) before that's complete. This means the entire sync operation
     must completed before
     
     */
    
    /// This group keeps track of work that is synchronization exlcusive.
    ///
    /// Note: syncGroup tracks tasks that are being performed on the sync context's queue. The coordinator group allows for tasks for be tracked
    /// more generally, or to track a group of tasks.
    let coordinatorGroup: DispatchGroup = DispatchGroup()
    let coordinatorQueue: DispatchQueue = DispatchQueue(label: "blockv-websocket-private-queue", qos: .default)
    
    let remote: RemoteInterface
    var socket: SocketSubscription

    fileprivate var observerTokens: [NSObjectProtocol] = [] //< The tokens registered with NotificationCenter
    let changeProcessors: [ChangeProcessor] //< The change processors for upload, download, etc.
    var teardownFlag = atomic_flag()
    
    var inventoryHash: String?
    
    /// Initialize using a `NSPersistentContainer` and an interface for the remote backend.
    init(container: NSPersistentContainer, remote: RemoteInterface, socket: SocketSubscription) {
        
        // this is objcio way's of switching between remote interfaces
//        remote = ProcessInfo.processInfo.environment[RemoteTypeEnvKey]?.lowercased() == "console" ? ConsoleRemote() : CloudKitRemote()
        self.remote = remote
        self.socket = socket
        self.viewContext = container.viewContext
        self.syncContext = container.newBackgroundContext()
        self.syncContext.name = "SyncCoordinator"
        self.syncContext.mergePolicy = VatomMergePolicy(mode: .remote)
        self.changeProcessors = [VatomDownloader(), VatomRemover()]
        self.setup()
        
    }
    
    /// The `tearDown` method must be called in order to stop the sync coordinator.
    func tearDown() {
        guard !atomic_flag_test_and_set(&teardownFlag) else { return }
        perform {
            self.removeAllObserverTokens()
        }
    }
    
    deinit {
        guard atomic_flag_test_and_set(&teardownFlag) else { fatalError("deinit called without tearDown() being called.") }
        // We must not call tearDown() at this point, because we can not call async code from within deinit.
        // We want to be able to call async code inside tearDown() to make sure things run on the right thread.
    }
    
    fileprivate func setup() {
        self.perform {
            // All these need to run on the same queue, since they're modifying `observerTokens`
//            self.remote.fetchUserID { self.viewContext.userID = $0 }
            self.setupContexts()
            self.setupChangeProcessors()
            self.setupApplicationActiveNotifications()
        }
    }

}

// MARK: - Context Owner -

extension SyncCoordinator: ContextOwner {
    
    /// The sync coordinator holds onto tokens used to register with the NotificationCenter.
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }
    func removeAllObserverTokens() {
        observerTokens.removeAll()
    }
    
    /// Disrtribute the objects to all change processors.
    func processChangedLocalObjects(_ objects: [NSManagedObject]) {
        for cp in changeProcessors {
            cp.processChangedLocalObjects(objects, in: self)
        }
    }
}

// MARK: - Context -

extension SyncCoordinator: ChangeProcessorContext {
    
    /// This is the context that the sync coordinator, change processors, and other sync components do work on.
    var context: NSManagedObjectContext {
        return syncContext
    }
    
    
    /*
     syncGroup: Keeps track of what work is going on
     syncQueue: Actually serialies the tasks.

     
     Most calls to `perform` do not care about the state of the `syncGroup`. They simply dispatch work onto the sync queue
     which, since it's a private serial queue, will be processed sequentially.
     The sync coordinator will hower enter the group when the work is scheduled (even though it may still be blocked by
     stuff in the queue) and will call `leave` when the block has completed (provided is was a synchronous block).
     
     The call to `performWhenEmpty` takes into account the state of the `syncGroup`. It only schedules the work once the
     group is empty.
     */
    
    /// Dispatches the block onto the sync queue only when the `syncGroup` is empty.
    ///
    /// The `syncGroup` is empty once all tasks in the group have finnished executing.  This is in contrast to calling `perform(_ block:)` which
    /// adds a task to the group immediately.
    ///
    /// For both `perform` and `performWhenEmpty` the taks will only begin when the backing queue is able to process it.
    func performWhenEmpty(_ block: @escaping () -> Void) {
        let queue = DispatchQueue.global(qos: .default)
        // wait for the group to be empty
        syncGroup.notify(queue: queue) {
            self.perform {
                block()
            }
        }
    }
    
    /// Dispatches the block onto the sync context's queue to be run. The sync group is entered immediately and only exited once the completion
    /// handler is invoked.
    ///
    /// This method is useful for blocks that have asynchronour components. Note however, that if the block dispatches to another queue, the
    /// suny queue may be idle.
//    func perform(_ block: @escaping (_ completion: () -> Void) -> Void) {
//        syncContext.performAsync(group: syncGroup, block: block)
//    }
    
    
    /// Dispatches the block onto the sync context's queue to be run. The sync group is entered immediately and exited once the block has been
    /// processed.
    ///
    /// This method is useful for blocks without asynchronous components.
    func perform(_ block: @escaping () -> ()) {
        syncContext.perform(group: syncGroup, block: block)
    }
    
    func perform<A,B>(_ block: @escaping (A,B) -> ()) -> (A,B) -> () {
        return { (a: A, b: B) -> () in
            self.perform {
                block(a, b)
            }
        }
    }
    
    func perform<A,B,C>(_ block: @escaping (A,B,C) -> ()) -> (A,B,C) -> () {
        return { (a: A, b: B, c: C) -> () in
            self.perform {
                block(a, b, c)
            }
        }
    }
    
    func delayedSaveOrRollback() {
        context.delayedSaveOrRollback(group: syncGroup)
    }
}


// MARK: Setup
extension SyncCoordinator {
    fileprivate func setupChangeProcessors() {
        for cp in self.changeProcessors {
            cp.setup(for: self)
        }
    }
}

// MARK: - Active & Background -

extension SyncCoordinator: ApplicationActiveStateObserving {
    
    func applicationDidBecomeActive() {
        fetchLocallyTrackedObjects()
        fetchRemoteDataForApplicationDidBecomeActive()
    }
    
    func applicationDidEnterBackground() {
        syncContext.refreshAllObjects()
    }
    
    fileprivate func fetchLocallyTrackedObjects() {
        self.perform {
            // TODO: Could optimize this to only execute a single fetch request per entity.
            var objects: Set<NSManagedObject> = []
            for cp in self.changeProcessors {
                guard let entityAndPredicate = cp.entityAndPredicateForLocallyTrackedObjects(in: self) else { continue }
                let request = entityAndPredicate.fetchRequest
                request.returnsObjectsAsFaults = false
                let result = try! self.syncContext.fetch(request)
                objects.formUnion(result)
            }
            self.processChangedLocalObjects(Array(objects))
        }
    }
    
}

// MARK: - Remote -

extension SyncCoordinator {
    
    /*
     Fixme, there is a distinction between 'fetchLatest'
     */
    
    fileprivate func fetchRemoteDataForApplicationDidBecomeActive() {
        switch VatomCD.count(in: context) {
        case 0: self.fetchLatestRemoteData()
        default: self.fetchNewRemoteData()
        }
    }
    
    /// Informs each change processor to fetch remote records (i.e. refresh).
    fileprivate func fetchLatestRemoteData() {
        
        //TODO: Pause web socket
        perform {
            for changeProcessor in self.changeProcessors {
                changeProcessor.fetchLatestRemoteRecords(in: self)
                self.delayedSaveOrRollback()
            }
        }
        //TODO: Unpause web socket
        
    }
    
    /*
     This should use the sync stuff to fetch only changed/new
     */
    fileprivate func fetchNewRemoteData() {
        
        //FIXME: This is not meant to be here
        perform {
            for changeProcessor in self.changeProcessors {
                changeProcessor.fetchLatestRemoteRecords(in: self)
                self.delayedSaveOrRollback()
            }
        }
        
//        remote.fetchNewMoods { changes, callback in
//            self.processRemoteChanges(changes) {
//                self.perform {
//                    self.context.delayedSaveOrRollback(group: self.syncGroup) { success in
//                        callback(success) // cloudkit needs a signal when all is done. bv backend does not
//                    }
//                }
//            }
//        }
    }
    
    fileprivate func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], completion: @escaping () -> ()) {
        self.changeProcessors.asyncForEach(completion: completion) { changeProcessor, innerCompletion in
            perform {
                changeProcessor.processRemoteChanges(changes, in: self, completion: innerCompletion)
            }
        }
    }
    
    // MARK: - Public
    
    /// Refreshes all data from remote. (I am not sure this method should be exposed).
    public func _refresh() {
        self.fetchLatestRemoteData()
    }
    
    func handleSocketMessage(message: WSStateUpdateEvent) {
        
        /*
         The idea is that the dispatch group monitors the asynchronous operations, like a v1 inventory full sync.
         So when the sync starts, the dispatch group is entered, and when it completes, it exits.
        
         In the mean time, a socket message might come down, if it's inventory related e.g. added, removed, state_update
         then it must only be processed on the sync queue *after* the entrie
         */
        
        /*
         "Dispatch groups are a way of letting you keep track of work on queues." - https://developer.apple.com/videos/play/wwdc2016/720/ - 9:45
         This solve the problem of the caller (me) not knowing what work is running on a queue. It's all hidden.
         
         */
        
        self.coordinatorGroup.notify(queue: self.coordinatorQueue) { // hops onto the coordinator queue
            self.syncContext.perform { // hops onto the (opaque) queue backing the sync context
                // ...do socket operations
                
                // gotta be careful there is not too much queue hoping going on
            }
        }
        
        // OR
        
        let queue = DispatchQueue.global(qos: .default)
        coordinatorGroup.notify(queue: queue) { // bounces onto global queue (at least that's better than the main queue)
            
            self.syncContext.perform { // hops onto the (opaque) queue backing the sync context
                // ... do socket operations
                
                
            }
        }
        
        // OR
        
        /*
         Use an array to queue up the web socket messages, presumably on the main queue, or non-main queue, and then
         execute a single perform block on the sync context.
         */
        
    }
    
}

extension SyncCoordinator { // :SocketNotificationDrain
    
    /*
     Plan:
     - Use the `perform` block to dispatch socket processing logic. This places the API interaction code and the socket
     code on a single queue. Therefore, the asyn synchronization challenges, e.g. 'pause' web socket while fetching
     all vatoms should be taken care of.
     
     Q If inventory sync is broken into multiple fetch requests, what 'blocks' the queue until all requests are done.
     In otherwords, vatom downloader must block it's sync operation. 
     */
    
    /*
     This is where the the sync coordinator gets notified of remote changes. In Moody, there appears to be only a single
     signal to go and fetch new data. With BV, the notifications are more complex. The data comes down as
     */
    
    public func didReceiveRemoteNotification() {
        perform {
            self.fetchNewRemoteData()
        }
    }
    
    func didReceiveInventoryUpdate() {
        
        // switch on the sync context's queue (to maintain synchronization)
        self.perform {
            //
        }
        
    }
    
}

extension SyncCoordinator {
    
    func doFullSyncV1() {
        
        /*
         The coordinator group is entered at the start, and exited only once the entire sync operation has completed.
         
         - Enter the coordinator group
         - Recurse all inventory pages.
         - - For each page, use the syncContext's perform method to create the MOs, and save them to disk.
         - When the last page has been processed, leave the coordinator group
         
         Leaving the coordinator group *should* cause it to be empty and allow all the web socket message blocks
         to be processed.
         
         Q: How much of the sync code should be here, vs. being in a change processor.
         Q: What if the sync fails. There is no way to propagate the error. If it were an Operation, there could be properties e.g. `failed` to indicate this.
         Q: How do I prevent duplicate synchronizations?
         */
        
        self.coordinatorGroup.enter()
        
        
        
        
    }
    
}
