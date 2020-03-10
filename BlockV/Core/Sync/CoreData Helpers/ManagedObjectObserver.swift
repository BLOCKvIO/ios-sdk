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

public final class ManagedObjectObserver {
    public enum ChangeType {
        case delete
        case update
    }
    
    public init?(object: Managed, changeHandler: @escaping (ChangeType) -> ()) {
        guard let moc = object.managedObjectContext else { return nil }
        objectHasBeenDeleted = !type(of: object).defaultPredicate.evaluate(with: object)
        token = moc.addObjectsDidChangeNotificationObserver { [unowned self] note in
            guard let changeType = self.changeType(of: object, in: note) else { return }
            self.objectHasBeenDeleted = changeType == .delete
            changeHandler(changeType)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(token)
    }
    
    
    // MARK: Private
    
    fileprivate var token: NSObjectProtocol!
    fileprivate var objectHasBeenDeleted: Bool = false
    
    fileprivate func changeType(of object: Managed, in note: ObjectsDidChangeNotification) -> ChangeType? {
        let deleted = note.deletedObjects.union(note.invalidatedObjects)
        if note.invalidatedAllObjects || deleted.containsObjectIdentical(to: object) {
            return .delete
        }
        let updated = note.updatedObjects.union(note.refreshedObjects)
        if updated.containsObjectIdentical(to: object) {
            let predicate = type(of: object).defaultPredicate
            if predicate.evaluate(with: object) {
                return .update
            } else if !objectHasBeenDeleted {
                return .delete
            }
        }
        return nil
    }
}

