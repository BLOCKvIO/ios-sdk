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
import PromiseKit

extension VatomModel {
    
    // MARK: - Children
    
    /// Fetches the child vatoms for the specified parent id.
    ///
    /// Available on both owned and unowned vatoms.
    ///
    /// - important:
    /// This method will inspect the 'inventory' and 'children' regions, if the regions are synchronized the vatoms
    /// are returned, if not, the regions are first synchronized. This means the method is potentially slow.
    public func listChildren(completion: @escaping (Result<[VatomModel], BVError>) -> Void) {
        
        // check if the vatom is in the owner's inventory region (and stabalized)
        DataPool.inventory().getStable(id: self.id).map { inventoryVatom -> Guarantee<[VatomModel]> in
            
            if inventoryVatom == nil {
                // inspect the child region (owner & unowned)
                return DataPool.children(parentID: self.id).getAllStable().map { $0 as! [VatomModel] } // swiftlint:disable:this force_cast
                
            } else {
                // filter current children
                let children = (DataPool.inventory().getAll() as! [VatomModel]) // swiftlint:disable:this force_cast
                    .filter { $0.props.parentID == self.id }
                return Guarantee.value(children)
                
            }
            
            //FIXME: Very strange double unwrapping - I think it's to do with .map double wrapping?
        }.done { body in
            body.done({ children in
                completion(.success(children))
            })
        }
        
    }
    
    /// Fetches the child vatoms for the specified parent id.
    ///
    /// Available on both owned and unowned vatoms.
    ///
    /// - important:
    /// This method will inspect the 'inventory' region irrespective of sync state. This means the method is fast.
    public func listCachedChildren(completion: @escaping (Result<[VatomModel], BVError>) -> Void) {
        
        //FIXME: Why does this only query the inventory region?
        // How do I distringuish between no children and region not finding the vatom id?
        
        let children = DataPool.inventory().getAll()
            .compactMap { $0 as? VatomModel }
            .filter { $0.props.parentID == self.id }
        
        completion(.success(children))
        
    }
    
}
