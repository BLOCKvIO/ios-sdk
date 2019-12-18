//
//  BLOCKv AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BLOCKv SDK License (the "License"); you may not use this file or
//  the BLOCKv SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BLOCKv SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import Foundation
import PromiseKit

//FIXME: This only makes sense if the vatom is in the inventory region. For other regions this will fail.

/// Extension to VatomModel add convenience methods for listing children from the perspective of a
/// container vatom.
extension VatomModel {

    /// Fetches the first-level child vatom of this container vatom.
    ///
    /// Available on both owned and unowned vatoms.
    ///
    /// - important:
    /// This method will inspect the 'inventory' and 'children' regions, if the regions are synchronized the vatoms
    /// are returned, if not, the regions are first synchronized. This means the method is potentially slow.
    public func listChildren(completion: @escaping (Swift.Result<[VatomModel], BVError>) -> Void) {

        // check if the vatom is in the owner's inventory region (and stabalized)
        DataPool.inventory().getStable(id: self.id).map { inventoryVatom -> Guarantee<[VatomModel]> in

            if inventoryVatom == nil {
                // inspect the child region (owner & unowned)
                return DataPool.children(parentID: self.id)
                    .getAllStable()
                    .map { $0 as! [VatomModel] } // swiftlint:disable:this force_cast

            } else {
                // filter current children
                let children = (DataPool.inventory()
                    .getAll()
                    .compactMap { $0 as? VatomModel }
                    .filter { $0.props.parentID == self.id })
                return Guarantee.value(children)
            }

        //FIXME: Very strange double unwrapping - I think it's to do with .map double wrapping?
        }.done { body in
            body.done({ children in
                completion(.success(children))
            })
        }

    }

    /// Fetches the first-level child vatoms for this container vatom.
    ///
    /// Only available on *owned* container vatoms (throws otherwise). Use this function to get a best-effort snapshot of the number of
    /// children contained by this vatom. This call is useful where getting the number of children is critical, e.g.
    /// face code in a re-use list.
    ///
    /// - important:
    /// This method will inspect the 'inventory' region irrespective of sync state. This means the method is fast but potentially unsynchronized.
    public func listCachedChildren() throws -> [VatomModel] {
        
        // ensure data-pool's session owner is the vatom's owner
        if self.props.owner != DataPool.currentUserId { throw DataPool.SessionError.currentUserPermission }

        // fetch children from inventory region
        let children = DataPool.inventory().getAll()
            .compactMap { $0 as? VatomModel }
            .filter { $0.props.parentID == self.id }

        return children

    }

}
