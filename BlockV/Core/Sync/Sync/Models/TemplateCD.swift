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

/*
 # Rational
 This managed class creates a 'mapper' between vatoms and their template, and the template to the associated faces
 and actions. This is not stricky neccessary, since queries can achive the same thing. However, added complexity ensure
 a fast (relationship traversal) when fetch a vatom's faces and actions (as opposed to a slow queury to the db based
 on template id).
 
 # Delete Chain
 
 Deleting a vatom should trigger a delete of it's template (if the template references no other vatoms).
 If deleted, all related faces and actions should be deleted.
 
 # Sort Decriptors
 
 It would be nice to be able to have UI to view all the templates, template variations, and vatoms.
 Templates can be organised by publisher. This can be achived by using predicate lookups on vatoms since it does
 not need to be fast (it's just debugging UI).
 */

/// Mapping entity between
public final class TemplateCD: NSManagedObject, Managed {
    
    @NSManaged fileprivate(set) var id: String
    
    // - relationships
    @NSManaged fileprivate(set) var vatoms: Set<VatomCD>
    @NSManaged fileprivate(set) var faces: Set<FaceCD>
    @NSManaged fileprivate(set) var actions: Set<ActionCD>
    
    /// Convenience method to update a vatom object.
//    static func findOrCreate(in context: NSManagedObjectContext, with vatomModel: VatomModel) -> TemplateCD { ???
//        let template: TemplateCD = context.insertObject()
////        template.id = ???
//        return template
//    }
    
}
