//
//  Vatom+Actoins.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/03/20.
//

import Foundation

extension Vatom {
    
    /// Transfers this vAtom to the specified token.
    ///
    /// Note: Calling this action will trigger the action associated with this vAtom's
    /// template. If an action has not been configured, an error will be generated.
    ///
    /// - Parameters:
    ///   - token: Phone, Email, or User ID
    ///   - type: Three outbound tokens are accepted: `.phone`, `.email`, and `.id`.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func transfer(toToken token: String, type: UserTokenType,
                         completion: @escaping (Data?, BVError?) -> Void) {
        
        let body = [
            "this.id": self.id,
            "new.owner.\(type.rawValue)": token
        ]
        
        // perform the action
        Blockv.performAction(name: "Transfer", payload: body) { (data, error) in
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
        
        let body: [String : Any] = [
            "this.id": self.id,
            "geo.pos": [
                "lat": latitude,
                "lon": longitude
            ]
        ]
        
        // perform the action
        Blockv.performAction(name: "Drop", payload: body) { (data, error) in
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
        Blockv.performAction(name: "Pickup", payload: body) { (data, error) in
            //TODO: should it be weak self?
            completion(data, error)
        }
        
    }
    
}
