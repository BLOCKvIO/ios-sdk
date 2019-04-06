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

// MARK: - Containment Management

/// Extension to VatomModel add convenience methods for dealing with the children from the perspective of a
/// container vatom.
extension VatomModel {

    /// - Parameters:
    ///   - result: Either `.success` associated with a model containing details of the change, or `.failure` in the
    ///             case of an error.
    public typealias UpdateResultHandler = (_ result: Result<VatomUpdateModel, BVError>) -> Void

    /// Adds the specified vatoms to this container vatom as first-level children.
    ///
    /// Essentially, the parent id of the specified vatom is updated to id of this container vatom. Those vatoms which
    /// may not be contained will not be updated.
    ///
    /// - important: This request preemptively updates the local data pool. Changes are rolled back if the network
    ///              request fails.
    ///
    /// - Parameters:
    ///   - vatoms: The child vatoms to add to this container.
    ///   - completion: The completion hanlder to call when the request is completed.
    ///                 This handler is executed on the main thread.
    public func addChildren(_ vatoms: [VatomModel], completion: UpdateResultHandler?) {

        // update parent id of vatom arguments to this container vatom's id
        self.updateVatoms(vatoms, withNewParentID: self.id, completion: completion)

    }

    /// Removes the specified vatoms from this container vatom and moves them up one level to this container's
    /// container (which may be the root ".").
    ///
    /// Essentially, the parent id of the frist level children is updated with the parent id of this container vatom.
    /// Those vatoms which may not be contained will not be updated.
    ///
    /// - important: This request preemptively updates the local data pool. Changes are rolled back if the network
    ///              request fails.
    ///
    /// - Parameters:
    ///   - vatoms: The child vatoms to add to this container.
    ///   - completion: The completion hanlder to call when the request is completed.
    ///                 This handler is executed on the main thread.
    public func separateChildren(_ vatoms: [VatomModel], completion: UpdateResultHandler?) {

        // update parent id of vatom arguments to this container vatom's *parent* id
        self.updateVatoms(vatoms, withNewParentID: self.props.parentID, completion: completion)

    }

    /// Removes all of the child vatoms from this container vatom and moves them up one level to this container's
    /// container (which may be the root ".").
    ///
    /// Essentially, the parent id of the frist level children is updated with the parent id of this container vatom.
    /// Those vatoms which may not be contained will not be updated.
    ///
    /// - important: This request preemptively updates the local data pool. Changes are rolled back if the network
    ///              request fails.
    ///
    /// - Parameters:
    ///   - vatoms: The child vatoms to add to this container.
    ///   - completion: The completion hanlder to call when the request is completed.
    ///                 This handler is executed on the main thread.
    public func separateAllChildren(completion: UpdateResultHandler?) {

        // list all childen, remove
        self.listChildren { result in
            switch result {
            case .success(let children):
                self.separateChildren(children, completion: completion)
            case .failure(let error):
                completion?(.failure(error))
            }
        }

    }

    /// Updates the parent id of the specified vatoms to the provided parent id.
    ///
    /// - Parameters:
    ///   - vatoms: The vatoms whose parent identifier is to be updated.
    ///   - parentID: Vatom identifier to be used as the parent id.
    ///   - completion: The completion hanlder to call when the request is completed.
    ///                 This handler is executed on the main thread.
    public func updateVatoms(_ vatoms: [VatomModel], withNewParentID parentID: String,
                             completion: UpdateResultHandler?) {

        // perform preemptive action, store undo functions
        let undos = vatoms.map {
            // tuple: (vatom id, undo function)
            (id: $0.id, undo: DataPool.inventory().preemptiveChange(id: $0.id,
                                                                    keyPath: "vAtom::vAtomType.parent_id",
                                                                    value: parentID))
        }

        // perform the request
        BLOCKv.setParentID(ofVatoms: vatoms, to: self.id) { result in
            switch result {
            case .success(let model):

                /*
                 # Note
                 The most likely scenario where there will be partial containment errors is when setting the parent id
                 to a container vatom of type `DefinedFolderContainerType`. However, as of writting, the server does
                 not enforce child policy rules so this always succeed (using the current API).
                 */

                // roll back only those failed containments
                let undosToRollback = undos.filter { !model.ids.contains($0.id) }
                undosToRollback.forEach { $0.undo() }
                // complete
                completion?(.success(model))
            case .failure(let error):
                // roll back all containments
                undos.forEach { $0.undo() }
                completion?(.failure(error))
            }
        }

    }

    /// Fetches the first-level child vatom of this container vatom.
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
    /// Only available on *owned* container vatoms. Use this function to get a best-effort snapshot of the number of
    /// children contained by this vatom. This call is useful where getting the number of children is critical, e.g.
    /// face code in a re-use list.
    ///
    /// - important:
    /// This method will inspect the 'inventory' region irrespective of sync state. This means the method is fast.
    public func listCachedChildren() -> [VatomModel] {

        // fetch children from inventory region
        let children = DataPool.inventory().getAll()
            .compactMap { $0 as? VatomModel }
            .filter { $0.props.parentID == self.id }

        return children

    }

}

// MARK: - Containment

extension VatomModel {
    
    /// Returns `true` if the vatom will accept a request to contain the child vatom, `false` otherwise.
    public func canContainChild(_ childVatom: VatomModel) -> Bool {
        
        // folder containers will always accept requests to contain children
        if self.rootType == .container(.folder) { return true }
        
        // defined containers will only accept requests to contain vatoms matching their child policy rules
        if self.rootType == .container(.defined) {
            return doesChildPolicyAllowContainmentOf(childVatom)
        }
        
        // standard vatoms cannot contain children
        // discover and package containers will not accept requests to contain children
        return false
        
    }
    
    /// Returns `true` if this vatom's child policy permits containment of the child vatom. `false` otherwise.
    private func doesChildPolicyAllowContainmentOf(_ childVatom: VatomModel) -> Bool {
        
        // check if any policies match this template variation
        for policy in self.props.childPolicy where policy.templateVariationID == childVatom.props.templateVariationID {
            
            // check if there is a maximum number of children
            if policy.creationPolicy.enforcePolicyCountMax {
                //FIXME: Check against child count
                return false
            } else {
                return true
            }
        }
        
        return false
        
    }
    
    /// Returns `true` if the vatom's root type is a 'Container' type.
    ///
    /// Container vatoms have the ability to have parent-child relationships.
    public var isContainer: Bool {
        if case RootType.container = self.rootType {
            return true
        }
        return false
    }
    
    /// Enum modeling the know root type.
    private var rootType: RootType {
        
        if self.props.rootType == "vAtom::vAtomType" {
            return .standard
        } else {
            if self.props.rootType.hasSuffix("FolderContainerType") {
                return .container(.folder)
            } else if self.props.rootType.hasSuffix("PackageContainerType") {
                return .container(.package)
            } else if self.props.rootType.hasSuffix("DiscoverContainerType") {
                return .container(.discover)
            } else if self.props.rootType.hasSuffix("DefinedFolderContainerType") {
                return .container(.defined)
            } else {
                return .unknown
            }
        }
        
    }
    
    private enum RootType: Equatable {
        case standard
        case container(ContainerType)
        case unknown
    }
    
    private enum ContainerType: Equatable {
        case folder
        case package
        case discover
        case defined
    }
    
}
