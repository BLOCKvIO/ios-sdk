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

public final class ActionCD: NSManagedObject {
    
    // MARK: - Root
    
    @NSManaged fileprivate var compoundName: String
    @NSManaged public fileprivate(set) var name: String
    @NSManaged public fileprivate(set) var templateID: String
    @NSManaged public fileprivate(set) var meta: MetaDataCD
    
    // MARK: - Relationships

    @NSManaged public fileprivate(set) var vatoms: Set<VatomCD>
    
}

extension ActionCD: Managed {}

extension ActionCD {
    
    static func insert(with actionModel: ActionModel, in context: NSManagedObjectContext) -> ActionCD {
        let actionCD: ActionCD = context.insertObject()
        actionCD.copyProps(from: actionModel, in: context)
        return actionCD
    }
    
    /// Convenience method to create or update an object.
    static func findOrCreate(with actionModel: ActionModel, in context: NSManagedObjectContext) -> ActionCD {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(compoundName), actionModel.compoundName)
        let actionCD = findOrCreate(in: context, matching: predicate) {
            $0.copyProps(from: actionModel, in: context)
        }
        return actionCD
    }
    
    private func copyProps(from model: ActionModel, in context: NSManagedObjectContext) {
        self.compoundName = model.compoundName
        self.name = model.name
        self.templateID = model.templateID
        if let meta = model.meta {
            self.meta = MetaDataCD.insert(with: meta, in: context)
        }
    }

}

extension ActionCD {
    
    var structModel: ActionModel {
        
        return ActionModel(compoundName: self.compoundName,
                           name: self.name,
                           templateID: self.templateID,
                           meta: self.meta.structModel)
    }
    
}
