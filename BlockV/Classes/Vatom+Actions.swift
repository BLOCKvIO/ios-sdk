//
//  Vatom+Actoins.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/03/20.
//

import Foundation

extension Vatom {
    
    /// Models the three type of tokens for outbound actions.
    public enum OutboundTokenType: String {
        case phone = "new.owner.phone_number"
        case email = "new.owner.email"
        case id    = "new.owner.id"
    }
    
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
