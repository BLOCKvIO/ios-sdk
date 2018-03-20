//
//  GroupModel.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/03/02.
//

import Foundation

/// A simple struct that holds the three components necessary to interaction with vAtoms.
///
/// These are:
/// 1. Array of vAtoms
/// 2. Array of all the faces associated with the vAtoms.
///   Technically, an array of all the faces linked to the parent templates of the vAtoms in the vAtoms array.
/// 3. Array of all the actions associated with the vAtoms.
///   Technically, an array of all the actions linked to the parent templates of the vAtoms in the vAtoms array.
public struct GroupModel: Decodable {
    
    public var vatoms: [Vatom]
    public var faces: [Face]
    public var actions: [Action]

}

// MARK: - Equatable

extension GroupModel: Equatable {}

public func ==(lhs: GroupModel, rhs: GroupModel) -> Bool {
    return lhs.faces == rhs.faces &&
    lhs.actions == rhs.actions &&
    lhs.vatoms == rhs.vatoms
}
