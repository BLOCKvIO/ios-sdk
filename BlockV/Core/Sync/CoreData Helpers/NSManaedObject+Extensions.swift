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


extension NSManagedObject {
    public func refresh(_ mergeChanges: Bool = true) {
        managedObjectContext?.refresh(self, mergeChanges: mergeChanges)
    }
}


extension NSManagedObject {
    public func changedValue(forKey key: String) -> Any? {
        return changedValues()[key]
    }
    public func committedValue(forKey key: String) -> Any? {
        return committedValues(forKeys: [key])[key]
    }
}

