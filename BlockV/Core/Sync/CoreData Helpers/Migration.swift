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


public func migrateStore<Version: ModelVersion>(from sourceURL: URL, to targetURL: URL, targetVersion: Version, deleteSource: Bool = false, progress: Progress? = nil) {
    guard let sourceVersion = Version(storeURL: sourceURL as URL) else { fatalError("unknown store version at URL \(sourceURL)") }
    var currentURL = sourceURL
    let migrationSteps = sourceVersion.migrationSteps(to: targetVersion)
    var migrationProgress: Progress?
    if let p = progress {
        migrationProgress = Progress(totalUnitCount: Int64(migrationSteps.count), parent: p, pendingUnitCount: p.totalUnitCount)
    }
    for step in migrationSteps {
        migrationProgress?.becomeCurrent(withPendingUnitCount: 1)
        let manager = NSMigrationManager(sourceModel: step.source, destinationModel: step.destination)
        migrationProgress?.resignCurrent()
        let destinationURL = URL.temporary
        for mapping in step.mappings {
            try! manager.migrateStore(from: currentURL, sourceType: NSSQLiteStoreType, options: nil, with: mapping, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
        }
        if currentURL != sourceURL {
            NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
        currentURL = destinationURL
    }
    try! NSPersistentStoreCoordinator.replaceStore(at: targetURL, withStoreAt: currentURL)
    if (currentURL != sourceURL) {
        NSPersistentStoreCoordinator.destroyStore(at: currentURL)
    }
    if (targetURL != sourceURL && deleteSource) {
        NSPersistentStoreCoordinator.destroyStore(at: sourceURL)
    }
}
