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


extension NSPersistentStoreCoordinator {
    // TODO(swift3) Migrate thise to NSPersistentContainer
    public static func destroyStore(at url: URL) {
        do {
            let psc = self.init(managedObjectModel: NSManagedObjectModel())
            try psc.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
        } catch let e {
            print("failed to destroy persistent store at \(url)", e)
        }
    }
    
    // TODO(swift3) Migrate thise to NSPersistentContainer
    public static func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) throws {
        let psc = self.init(managedObjectModel: NSManagedObjectModel())
        try psc.replacePersistentStore(at: targetURL, destinationOptions: nil, withPersistentStoreFrom: sourceURL, sourceOptions: nil, ofType: NSSQLiteStoreType)
    }
}
