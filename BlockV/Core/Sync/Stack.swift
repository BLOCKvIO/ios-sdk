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

// https://medium.com/@starecho/something-you-may-need-to-do-when-integrating-core-data-into-your-cocoapods-library-e8e8fad409b8

//TODO: This is sitting as a global function is that fine? (objc.io do it similarly).
//TODO: Rename to makeBlockvInventoryContainer ? There may be another container (in-memory) for the map?

/*
 This is the prime/first item in setting up the core data stack.
 */

/// Creates an `NSPersistentContainer` for the SDK's data model.
///
/// This container's `viewContext` can be used by the viewer (i.e. handed around the view controller graph).
func makeBlockvContainer() -> NSPersistentContainer {
    // get persistent container from framework
    let modelURL = Bundle(for: BLOCKv.self).url(forResource: "InventoryModel", withExtension: "momd")!
    let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
    let container = NSPersistentContainer(name: "InventoryModel", managedObjectModel: managedObjectModel)
    return container
}

/* Jessie Squires
 A few types he used, maybe they are useful?
 */

//struct CoreDataModel {
//    let name: String
//    let bundle: Bundle
//}
//
//
//class CoreDataStack {
//    let model: CoreDataModel
//    let managedObjectContext: NSManagedObjectContext
//    let persistantStoreCoordinator: NSPersistentStoreCoordinator
//}
