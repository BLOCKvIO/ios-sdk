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
    /// Poilcy max an min rules are evaluated locally.
    ///
    /// Only applicable to *owned* vatoms.
    private func doesChildPolicyAllowContainmentOf(_ childVatom: VatomModel) -> Bool {

        // check if any policies match this template variation
        for policy in self.props.childPolicy where policy.templateVariationID == childVatom.props.templateVariationID {

            // check if there is a maximum number of children
            if policy.creationPolicy.enforcePolicyCountMax {
                // get cached children (owned vatoms only)
                guard let children = try? self.listCachedChildren() else {
                    return false
                }
                // check if current child count is less then policy max
                let filteredChildren = children.filter {
                    $0.props.templateVariationID ==  policy.templateVariationID
                }
                if policy.creationPolicy.policyCountMax > filteredChildren.count {
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
