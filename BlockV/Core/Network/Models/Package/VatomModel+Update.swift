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
    
    /// Returns a new `VatomModel` updated with the properties of the partial state update.
    public mutating func updated(applying stateUpdate: WSStateUpdateEvent) -> VatomModel? {
        
        /*
         This function operates by creating a mutable copy of self, and then updating each property present in the
         partial state update.
         */
        
        // create a copy
        var vatom = self
        
        // update meta data
        if let dateString = stateUpdate.vatomProperties["when_modified"]?.stringValue,
            let date = DateFormatter.blockvDateFormatter.date(from: dateString) {
            vatom.whenModified = date
        }
        
        // update root
        if let rootProperties = stateUpdate.vatomProperties["vAtom::vAtomType"] {
            
            rootProperties["category"]?.stringValue.flatMap { vatom.props.category = $0 }
            rootProperties["description"]?.stringValue.flatMap { vatom.props.description = $0 }
            
            rootProperties["num_direct_clones"]?.floatValue.flatMap { vatom.props.numberDirectClones = Int($0) }
            rootProperties["owner"]?.stringValue.flatMap { vatom.props.owner = $0 }
            rootProperties["parentID"]?.stringValue.flatMap { vatom.props.parentID = $0 }
            
            rootProperties["cloned_from"]?.stringValue.flatMap { vatom.props.clonedFrom = $0 }
            rootProperties["cloning_score"]?.floatValue.flatMap { vatom.props.cloningScore = Double($0) }
            
            rootProperties["acquirable"]?.boolValue.flatMap { vatom.props.isAcquirable = $0 }
            rootProperties["redeemable"]?.boolValue.flatMap { vatom.props.isRedeemable = $0 }
            rootProperties["disabled"]?.boolValue.flatMap { vatom.props.isDisabled = $0 }
            rootProperties["dropped"]?.boolValue.flatMap { vatom.props.isDropped = $0 }
            rootProperties["tradeable"]?.boolValue.flatMap { vatom.props.isTradeable = $0 }
            rootProperties["transferable"]?.boolValue.flatMap { vatom.props.isTransferable = $0 }
            
        }
        
        // update private
        if let privateProperties = stateUpdate.vatomProperties["private"] {
            if let newPrivate = vatom.private?.updated(applying: privateProperties) {
                vatom.private = newPrivate
            }
        }
        
        return vatom
        
    }
    
}
