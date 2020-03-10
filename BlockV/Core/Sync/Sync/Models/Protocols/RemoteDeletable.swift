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

private let MarkedForRemoteDeletionKey = "markedForRemoteDeletion"

public protocol RemoteDeletable: class {
    var changedForRemoteDeletion: Bool { get }
    var markedForRemoteDeletion: Bool { get set }
    func markForRemoteDeletion()
}


extension RemoteDeletable {
    public static var notMarkedForRemoteDeletionPredicate: NSPredicate {
        return NSPredicate(format: "%K == false", MarkedForRemoteDeletionKey)
    }
    
    public static var markedForRemoteDeletionPredicate: NSPredicate {
        return NSCompoundPredicate(notPredicateWithSubpredicate: notMarkedForRemoteDeletionPredicate)
    }
    
    /// Marks an object to be deleted remotely, on the backend (i.e. Cloud Kit).
    /// Once it has been deleted on the backend, it will get marked for deletion locally by the sync code base.
    /// An object marked for remote deletion will no longer match the `notMarkedForDeletionPredicate`.
    public func markForRemoteDeletion() {
        markedForRemoteDeletion = true
    }
}


extension RemoteDeletable where Self: NSManagedObject {
    public var changedForRemoteDeletion: Bool {
        return changedValue(forKey: MarkedForRemoteDeletionKey) as? Bool == true
    }
}


extension RemoteDeletable where Self: DelayedDeletable {
    public static var notMarkedForDeletionPredicate: NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notMarkedForLocalDeletionPredicate, notMarkedForRemoteDeletionPredicate])
    }
}
