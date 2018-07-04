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

/// This file adds actions to VatomModel (simply for convenience).
extension VatomModel {

    /// Transfers this vAtom to the specified token.
    ///
    /// Note: Calling this action will trigger the action associated with this vAtom's
    /// template. If an action has not been configured, an error will be generated.
    ///
    /// - Parameters:
    ///   - token: Standard UserToken (Phone, Email, or User ID)
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func transfer(toToken token: UserToken,
                         completion: @escaping (Data?, BVError?) -> Void) {

        let body = [
            "this.id": self.id,
            "new.owner.\(token.type.rawValue)": token.value
        ]

        // perform the action
        BLOCKv.performAction(name: "Transfer", payload: body) { (data, error) in
            //TODO: should it be weak self?
            completion(data, error)
        }

    }

    /// Drops this vAtom as the specified location.
    ///
    /// Note: Calling this action will trigger the action associated with this vAtom's
    /// template. If an action has not been configured, an error will be generated.
    ///
    /// - Parameters:
    ///   - latitude: The latitude component of the coordinate.
    ///   - longitude: The longitude component of the coordinate.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func drop(latitude: Double, longitude: Double,
                     completion: @escaping (Data?, BVError?) -> Void) {

        let body: [String: Any] = [
            "this.id": self.id,
            "geo.pos": [
                "lat": latitude,
                "lon": longitude
            ]
        ]

        // perform the action
        BLOCKv.performAction(name: "Drop", payload: body) { (data, error) in
            //TODO: should it be weak self?
            completion(data, error)
        }

    }

    /// Picks up this vAtom from it's dropped location.
    ///
    /// Note: Calling this action will trigger the action associated with this vAtom's
    /// template. If an action has not been configured, an error will be generated.
    ///
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func pickUp(completion: @escaping (Data?, BVError?) -> Void) {

        let body = [
            "this.id": self.id
        ]

        // perform the action
        BLOCKv.performAction(name: "Pickup", payload: body) { (data, error) in
            //TODO: should it be weak self?
            completion(data, error)
        }

    }

}
