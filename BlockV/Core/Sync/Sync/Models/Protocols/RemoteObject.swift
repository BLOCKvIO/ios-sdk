//
//  RemoteObject.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2019/07/14.
//

import Foundation

public protocol RemoteObject: class { }

internal let RemoteIdentifierKey = "id"

extension RemoteObject {
    
    public static func predicateForRemoteIdentifiers(_ ids: [RemoteRecordID]) -> NSPredicate {
        return NSPredicate(format: "%K in %@", RemoteIdentifierKey, ids)
    }
    
}

extension VatomCD: RemoteObject {}
extension FaceCD: RemoteObject {}
extension ActionCD: RemoteObject {}
