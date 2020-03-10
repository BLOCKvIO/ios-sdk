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

final class VatomDropActioner: ElementChangeProcessor {
    
    var elementsInProgress = InProgressTracker<VatomCD>()
    
    func setup(for context: ChangeProcessorContext) {
        // no-op
    }
    
    func processChangedLocalElements(_ elements: [VatomCD], in context: ChangeProcessorContext) {
//        processDroppedVatom(elements: elements, context: context)
    }
    
    func processRemoteChanges<T>(_ changes: [RemoteRecordChange<T>], in context: ChangeProcessorContext, completion: () -> ()) {
        // no-op
        completion()
    }
    
    func fetchLatestRemoteRecords(in context: ChangeProcessorContext) {
        // no-op
    }
    
    var predicateForLocallyTrackedElements: NSPredicate {
        let marked = VatomCD.markedForRemoteDeletionPredicate
        let notDeleted = VatomCD.notMarkedForLocalDeletionPredicate
        return NSCompoundPredicate(andPredicateWithSubpredicates: [marked, notDeleted])
    }
    
}

extension VatomDropActioner {
    
    func processDroppedVatom(elements: Set<VatomCD>, context: ChangeProcessorContext) {
        
        for element in elements {
            
            let payload: [String: Any] = ["this.id": element.id, "geo.pos": [
                "lon": -26.106643,
                "lat": 28.0548073
                ]]
            
//            context.remote.performAction(name: "Drop", payload: payload, completion: <#T##(Result<[String : Any], BVError>) -> Void#>)
            
            
        }
        
    }
    
}
