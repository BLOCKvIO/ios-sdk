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
 Resources are defined at the template-variation level. This means there is a many-to-many relationship between vatom
 and resource (since mutiple vatoms may be emited from a single template-variation).
 */

public final class ResourceCD: NSManagedObject {
    
    @NSManaged public fileprivate(set) var name: String
    @NSManaged public fileprivate(set) var type: String
    @NSManaged public fileprivate(set) var url: URL
    
}

extension ResourceCD: Managed {}

extension ResourceCD {
    
    static func findOrCreateResource(in context: NSManagedObjectContext, with resourceModel: VatomResourceModel) -> ResourceCD {

        let predicate = NSPredicate(format: "%K == %@ AND %K == %@ AND %K == %@",
                                    #keyPath(name), resourceModel.name,
                                    #keyPath(type), resourceModel.type,
                                    #keyPath(url), resourceModel.url as NSURL)
        
        let resource = findOrCreate(in: context, matching: predicate) {
            $0.name = resourceModel.name
            $0.type = resourceModel.type
            $0.url = resourceModel.url
        }
        
        return resource
    }
}

extension ResourceCD {
    
    static func findOrCreateResource(in context: NSManagedObjectContext, with descriptor: [String: Any]) throws -> ResourceCD {

        guard
            let _name = descriptor["name"] as? String,
            let _type = descriptor["resourceType"] as? String,
            let _value = (descriptor["value"] as? [String: Any])?["value"] as? String,
            let _url = URL(string: _value)
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }
        
        let predicate = NSPredicate(format: "%K == %@ AND %K == %@ AND %K == %@",
                                    #keyPath(name), _name,
                                    #keyPath(type), _type,
                                    #keyPath(url), _url as NSURL)
        
        let resource = findOrCreate(in: context, matching: predicate) {
            $0.name = _name
            $0.type = _type
            $0.url = _url
        }

        return resource
    }
}

extension ResourceCD {
    
    var structModel: VatomResourceModel {
        return VatomResourceModel(name: self.name, type: self.type, url: self.url)
    }
    
}
