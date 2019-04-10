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

// Core overlays to support Data Pool.

// PromiseKit Overlays
internal extension Client {

    func request(_ endpoint: Endpoint<Void>) -> Promise<Data> {
        return Promise { self.request(endpoint, completion: $0.resolve) }
    }

    func requestJSON(_ endpoint: Endpoint<Void>) -> Promise<Any> {
        return Promise { self.requestJSON(endpoint, completion: $0.resolve) }
    }

}

internal extension API {

    /// Raw endpoints are generic over `Void`. This informs the networking client to return the raw data (instead of
    /// parsing out a model).
    ///
    /// NB: `Void` endpoints don't partake in the auth cycle.
    enum Raw {

        /// Builds the endpoint to search for vAtoms.
        static func discover(_ payload: [String: Any]) -> Endpoint<Void> {

            return Endpoint(method: .post,
                            path: "/v1/vatom/discover",
                            parameters: payload)
        }

        /// Build the endpoint to fetch the inventory.
        static func getInventory(parentID: String,
                                 page: Int = 0,
                                 limit: Int = 0) -> Endpoint<Void> {
            return Endpoint(method: .post,
                            path: "/v1/user/vatom/inventory",
                            parameters: [
                                "parent_id": parentID,
                                "page": page,
                                "limit": limit
                ]
            )
        }

        /// Builds the endpoint to get a vAtom by its unique identifier.
        static func getVatoms(withIDs ids: [String]) -> Endpoint<Void> {
            return Endpoint(method: .post,
                            path: "/v1/user/vatom/get",
                            parameters: ["ids": ids]
            )
        }
        
        /// Builds the endpoint to update a vatom.
        static func updateVatom(payload: [String: Any]) -> Endpoint<Void> {
            return Endpoint(method: .post,
                            path: "/v1/vatoms",
                            parameters: payload)
        }

    }

}
