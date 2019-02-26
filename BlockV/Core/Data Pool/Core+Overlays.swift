//
//  Core+Overlays.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2019/02/22.
//

import Foundation
import PromiseKit

/*
 This file contains a set of Core overlays to support Data Pool.
 */

/// PromiseKit Overlays
internal extension Client {

    //    func fetchAvatar(user: String) -> Promise<UIImage> {
    //        return Promise { fulfill, reject in
    //            MyWebHelper.GET("\(user)/avatar") { data, err in
    //                guard let data = data else { return reject(err) }
    //                guard let img = UIImage(data: data) else { return reject(MyError.InvalidImage) }
    //                guard let img.size.width > 0 else { return reject(MyError.ImageTooSmall) }
    //                fulfill(img)
    //            }
    //        }
    //    }

    func request(_ endpoint: Endpoint<Void>) -> Promise<Data> {

        //FIXME: Double check this works
        return Promise { self.request(endpoint, completion: $0.resolve) }

//        return Promise { fullfill, reject in
//            self.request(endpoint) { data, error in
//                //FIXME: Should the error be checked?
//                guard let data = data else { return reject(error) }
//                fulfill(data)
//            }
//        }
    }

}

internal extension API {

    /// Raw endpoints are generic over `Void`. This informs the networking client to return then raw data (instead of
    /// parsing out a model).
    enum Raw {

        /// Builds the endpoint to search for vAtoms.
        ///
        /// - Parameter payload: Raw request payload.
        /// - Returns: Endpoint generic over `UnpackedModel`.
        static func discover(_ payload: [String: Any]) -> Endpoint<Void> {

            return Endpoint(method: .post,
                            path: "/v1/vatom/discover",
                            parameters: payload)
        }

        /// Builds the endpoint to get a vAtom by its unique identifier.
        ///
        /// The endpoint is generic over a response model. This model is parsed on success responses (200...299).
        static func getVatoms(withIDs ids: [String]) -> Endpoint<Void> {
            return Endpoint(method: .post,
                            path: "/v1/user/vatom/get",
                            parameters: ["ids": ids]
            )
        }

    }

}
