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


final class EntityAndPredicate<A : NSManagedObject> {
    let entity: NSEntityDescription
    let predicate: NSPredicate
    
    init(entity: NSEntityDescription, predicate: NSPredicate) {
        self.entity = entity
        self.predicate = predicate
    }
}


extension EntityAndPredicate {
    var fetchRequest: NSFetchRequest<A> {
        let request = NSFetchRequest<A>()
        request.entity = entity
        request.predicate = predicate
        return request
    }
}


extension Sequence where Iterator.Element: NSManagedObject {
    func filter(_ entityAndPredicate: EntityAndPredicate<Iterator.Element>) -> [Iterator.Element] {
        typealias MO = Iterator.Element
        let filtered = filter { (mo: Iterator.Element) -> Bool in
            guard mo.entity === entityAndPredicate.entity else { return false }
            return entityAndPredicate.predicate.evaluate(with: mo)
        }
        return Array(filtered)
    }
}
