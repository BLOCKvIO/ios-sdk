//
//  Vatom+Actoins.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/03/20.
//

import Foundation

extension Vatom {
    
    /// Models the three type of tokens for available for outbound actions.
    public enum OutboundTokenType: String {
        case phone  = "new.owner.phone_number"
        case email  = "new.owner.email"
        case userID = "new.owner.id"
    }
    
    /// Transfers this vAtom to the specified token.
    ///
    /// Note: Calling this action will trigger the action associated with this vAtom's
    /// template. If an action has not been configured, an error will be generated.
    ///
    /// - Parameters:
    ///   - token: Phone, Email, or User ID
    ///   - type: Three outbound tokens are accepted: `.phone`, `.email`, and `.id`.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public func transfer(toToken token: String, type: OutboundTokenType,
                         completion: @escaping (Data?, BVError?) -> Void) {
        
        Blockv.performAction(name: "Transfer",
                             payload: [
                                "this.id": self.id,
                                type.rawValue: token
            ]) { (data, error) in
                // should it be weak self?
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
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public func drop(latitude: Double, longitude: Double,
                     completion: @escaping (Data?, BVError?) -> Void) {
        
        Blockv.performAction(name: "Drop",
                             payload: [
                                "this.id": self.id,
                                "geo.pos": [
                                    "lat": latitude,
                                    "lon": longitude
                                ]
        ]) { (data, error) in
            // should it be weak self?
            completion(data, error)
        }
    }
    
    /// Picks up the vAtom from it's dropped location.
    ///
    /// Note: Calling this action will trigger the action associated with this vAtom's
    /// template. If an action has not been configured, an error will be generated.
    ///
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public func pickUp(completion: @escaping (Data?, BVError?) -> Void) {
     
        Blockv.performAction(name: "Pickup",
                             payload: [
                                "this.id": self.id
        ]) { (data, error) in
            // should it be weak self?
            completion(data, error)
        }
        
    }
        
}
