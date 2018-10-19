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

extension VatomModel {

    /// Returns a new `VatomModel` updated with the properties of the partial state update. If the vAtom identifiers
    /// do not match `nil` is returned.
    ///
    /// This function operates by creating a mutable copy of self, and then updating each property present in the
    /// partial state update. The returned `VatomModel` represents the state *after* the state update event has been
    /// applied.
    ///
    /// This method should be called when a state update event is received from the Web socket.
    public func updated(applying stateUpdate: WSStateUpdateEvent) -> VatomModel? { // swiftlint:disable:this function_body_length

        // ensure vatom ids match
        guard self.id == stateUpdate.vatomId else {
            assertionFailure("Programmer error. Identifier of state update vAtom must match self's identifier.")
            return nil
        }

        // create a copy
        var vatom = self

        // update meta data
        if let dateString = stateUpdate.vatomProperties["when_modified"]?.stringValue,
            let date = DateFormatter.blockvDateFormatter.date(from: dateString) {
            vatom.whenModified = date
        }
        stateUpdate.vatomProperties["unpublished"]?.boolValue.flatMap { vatom.isUnpublished = $0 }

        // update root
        if let rootProperties = stateUpdate.vatomProperties["vAtom::vAtomType"] {

            rootProperties["parent_id"]?.stringValue.flatMap { vatom.props.parentID = $0 }
            rootProperties["owner"]?.stringValue.flatMap { vatom.props.owner = $0 }
            rootProperties["notify_msg"]?.stringValue.flatMap { vatom.props.notifyMessage = $0 }
            rootProperties["tags"]?.arrayValue.flatMap { vatom.props.tags = $0.compactMap { $0.stringValue } }
            rootProperties["notify_msg"]?.stringValue.flatMap { vatom.props.notifyMessage = $0 }
            rootProperties["in_contract"]?.boolValue.flatMap { vatom.props.isInContract = $0 }
            rootProperties["in_contract_with"]?.stringValue.flatMap { vatom.props.inContractWith = $0 }
            rootProperties["transferred_by"]?.stringValue.flatMap { vatom.props.transferredBy = $0 }
            rootProperties["num_direct_clones"]?.floatValue.flatMap { vatom.props.numberDirectClones = Int($0) }
            rootProperties["cloned_from"]?.stringValue.flatMap { vatom.props.clonedFrom = $0 }
            rootProperties["cloning_score"]?.floatValue.flatMap { vatom.props.cloningScore = Double($0) }
            rootProperties["acquirable"]?.boolValue.flatMap { vatom.props.isAcquirable = $0 }
            rootProperties["redeemable"]?.boolValue.flatMap { vatom.props.isRedeemable = $0 }
            rootProperties["disabled"]?.boolValue.flatMap { vatom.props.isDisabled = $0 }
            rootProperties["dropped"]?.boolValue.flatMap { vatom.props.isDropped = $0 }
            rootProperties["tradeable"]?.boolValue.flatMap { vatom.props.isTradeable = $0 }
            rootProperties["transferable"]?.boolValue.flatMap { vatom.props.isTransferable = $0 }

            rootProperties["visibility"]?["type"]?.stringValue.flatMap { vatom.props.visibility.type = $0 }
            rootProperties["visibility"]?["value"]?.stringValue.flatMap { vatom.props.visibility.value = $0 }

            rootProperties["commerce"]?["pricing"]?["pricingType"]?.stringValue
                .flatMap { vatom.props.commerce.pricing.pricingType = $0 }
            rootProperties["commerce"]?["pricing"]?["value"]?["currency"]?.stringValue
                .flatMap { vatom.props.commerce.pricing.currency = $0 }
            rootProperties["commerce"]?["pricing"]?["value"]?["price"]?.stringValue
                .flatMap { vatom.props.commerce.pricing.price = $0 }
            rootProperties["commerce"]?["pricing"]?["value"]?["valid_from"]?.stringValue
                .flatMap { vatom.props.commerce.pricing.validFrom = $0 }
            rootProperties["commerce"]?["pricing"]?["value"]?["valid_through"]?.stringValue
                .flatMap { vatom.props.commerce.pricing.validThrough = $0 }
            rootProperties["commerce"]?["pricing"]?["value"]?["vat_included"]?.boolValue
                .flatMap { vatom.props.commerce.pricing.isVatIncluded = $0 }

            //FIXME: There is a data type issue here. [18.68768, -33.824017] is converted to
            // [18.687679290771484, -33.82401657104492]
            rootProperties["geo_pos"]?["coordinates"]?.arrayValue.flatMap {
                vatom.props.geoPosition.coordinates = $0.compactMap { $0.floatValue }.map { Double($0) }
            }

            // TODO: Version

        }

        // update EOS
        if let eosPropsPartial = stateUpdate.vatomProperties["eos"] {
            if let updatedEOS = vatom.eos?.updated(applying: eosPropsPartial) {
                vatom.eos = updatedEOS
            }
        }
        // update ETH
        if let ethPropsPartial = stateUpdate.vatomProperties["eth"] {
            if let updatedETH = vatom.eth?.updated(applying: ethPropsPartial) {
                vatom.eth = updatedETH
            }
        }
        // update private
        if let privatePropsPartial = stateUpdate.vatomProperties["private"] {
            if let updatedPrivate = vatom.private?.updated(applying: privatePropsPartial) {
                vatom.private = updatedPrivate
            }
        }

        return vatom

    }

}
