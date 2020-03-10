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

public final class TagCD: NSManagedObject {
    
    @NSManaged public fileprivate(set) var name: String
    @NSManaged public fileprivate(set) var vatoms: Set<VatomCD>

}

extension TagCD: Managed {}

extension TagCD {
    
    /// Inserts a new tag into the context.
    ///
    /// Tags are have a uniqueness constraint on their name property.
    static func insert(tag tagName: String, in context: NSManagedObjectContext) -> TagCD {
        
        let tag: TagCD = context.insertObject()
        tag.name = tagName
        return tag
        
    }
    
    static func insert(tag tagName: String, for vatom: VatomCD, in context: NSManagedObjectContext) -> TagCD {
        
        let tag: TagCD = context.insertObject()
        tag.name = tagName
        tag.vatoms.insert(vatom)
        return tag
        
    }
    
    ///
    static func findOrCreate(tag tagName: String, for vatom: VatomCD, in context: NSManagedObjectContext) -> TagCD {
        let predicate = TagCD.predicate(format: "%K == %@", #keyPath(name), tagName)
        let tagCD = findOrCreate(in: context, matching: predicate) {
            $0.name = tagName
            $0.vatoms.insert(vatom)
        }
        return tagCD
    }
    
}
