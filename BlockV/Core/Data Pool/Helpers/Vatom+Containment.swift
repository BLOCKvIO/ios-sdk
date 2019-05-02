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

    /// Returns `true` if the container vatom will accept a request to contain the child vatom, `false` otherwise.
    ///
    /// Only applicable to *owned* vatoms.
    public func canContainChild(_ childVatom: VatomModel) -> Bool {

        // ensure this vatom is a container
        if !self.isContainer { return false }

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

    /// Returns `true` if this container vatom's child policy permits containment of the child vatom. `false` otherwise.
    ///
    /// Only applicable to *owned* vatoms.
    private func doesChildPolicyAllowContainmentOf(_ childVatom: VatomModel) -> Bool {

        // check if any policies match this template variation
        for policy in self.props.childPolicy where policy.templateVariationID == childVatom.props.templateVariationID {

            // check if there is a maximum number of children
            if policy.creationPolicy.enforcePolicyCountMax {
                // check if current child count is less then policy max
                if policy.creationPolicy.policyCountMax > self.listCachedChildren().count {
                    return true
                }
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

    /// Enum modeling the root type of this vatom.
    public var rootType: RootType {

        if self.props.rootType == "vAtom::vAtomType" {
            return .standard
        } else {
            if self.props.rootType.hasSuffix("::FolderContainerType") {
                return .container(.folder)
            } else if self.props.rootType.hasSuffix("::PackageContainerType") {
                return .container(.package)
            } else if self.props.rootType.hasSuffix("::DiscoverContainerType") {
                return .container(.discover)
            } else if self.props.rootType.hasSuffix("::DefinedFolderContainerType") {
                return .container(.defined)
            } else {
                return .unknown
            }
        }

    }

    public enum RootType: Equatable {
        case standard
        case container(ContainerType)
        case unknown
    }

    public enum ContainerType: Equatable {
        case folder
        case package
        case discover
        case defined
    }

}
