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

/// Tracks managed objects that are being *in progress*.
final class InProgressTracker<O: NSManagedObject> where O: Managed {
    
    /// Objects contained in this set are
    fileprivate var objectsInProgress = Set<O>()
    
    init() {}
    
    /// Returns those objects from the given `objects` that are not yet in progress.
    ///
    /// These new objects are then added to the `objectsInProgress` set.
    func objectsToProcess(from objects: [O]) -> [O] {
        let added = objects.filter { !objectsInProgress.contains($0) }
        objectsInProgress.formUnion(added)
        return added
    }
    
    /// Marks the given objects as being complete, i.e. no longer in progress.
    func markObjectsAsComplete(_ objects: [O]) {
        objectsInProgress.subtract(objects)
    }
    
}


extension InProgressTracker: CustomDebugStringConvertible {
    var debugDescription: String {
        var components = ["InProgressTracker"]
        components.append("count=\(objectsInProgress.count)")
        let all = objectsInProgress.map { $0.objectID.description }.joined(separator: ", ")
        components.append("{\(all)}")
        return components.joined(separator: " ")
    }
}
