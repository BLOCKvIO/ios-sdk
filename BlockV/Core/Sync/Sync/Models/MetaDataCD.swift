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

public final class MetaDataCD: NSManagedObject {
    
    @NSManaged public fileprivate(set) var createdBy: String
    @NSManaged public fileprivate(set) var dataType: String
    @NSManaged public fileprivate(set) var whenCreated: Date
    @NSManaged public fileprivate(set) var whenModified: Date
    
}

extension MetaDataCD: Managed {}

extension MetaDataCD {
    
    /// Convenience method to update a vatom object with a dictionary.
    static func insert(with metaModel: MetaModel, in context: NSManagedObjectContext) -> MetaDataCD {
        let meta: MetaDataCD = context.insertObject()
        meta.createdBy = metaModel.createdBy
        meta.dataType = metaModel.dataType
        meta.whenCreated = metaModel.whenCreated
        meta.whenModified = metaModel.whenModified
        return meta
    }
    
}

//extension MetaDataCD: JSONUpdatable {
//
//    static func update(into context: NSManagedObjectContext, with descriptor: [String : Any]) throws -> MetaDataCD {
//        guard
//            let _createdBy = descriptor["created_by"] as? String,
//            let _dataType = descriptor["data_type"] as? String,
//            let _whenCreated = descriptor["when_created"] as? String,
//            let _whenModified = descriptor["when_modified"] as? String
//        else {
//            throw BVError.modelDecoding(reason: "Model decoding failed.")
//
//        }
//
//        let meta: MetaDataCD = context.insertObject()
//        meta.createdBy = _createdBy
//        meta.dataType = _dataType
//        meta.whenCreated = DateFormatter.blockvDateFormatter.date(from: _whenCreated)! //FIXME: force
//        meta.whenModified = DateFormatter.blockvDateFormatter.date(from: _whenModified)! //FIXME: force
//        return meta
//    }
//
//}

extension MetaDataCD {
    
    var structModel: MetaModel {
        return MetaModel(createdBy: self.createdBy,
                         dataType: self.dataType,
                         whenCreated: self.whenCreated,
                         whenModified: self.whenModified)
    }
    
}
