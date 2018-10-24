//
//  VatomObserver.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/10/24.
//

import Foundation

class VatomObserver {
    
    // MARK: - Typealiases
    
    typealias StateUpdate = (_ vatomID: String, _ whenModified: Date, _ newProperties: [String : Any]) -> Void
    
    // MARK: - Properties
    
    /// Unique identifier of the root vAtom.
    public private(set) var rootVatomID: String
    /// Set of unique identifiers of root's child vAtoms.
    public private(set) var childVatomIDs: Set<String> = [] {
        didSet {
            // call closures with changes
            let added = childVatomIDs.subtracting(oldValue)
            let removed = oldValue.subtracting(childVatomIDs)
            added.forEach { self.onChildAdded?($0) }
            removed.forEach { self.onChildRemoved?($0) }
        }
    }
    
    // MARK: - Event Closures
    
    /*
     Consumers may assign closures to receive updates on events.
     */
    
    /// Closure that is called on state update of the root vAtom.
    var onStateUpdate: StateUpdate?
    /// Closure that is called when a child is added to the root vAtom.
    var onChildAdded: ((_ vatomID: String) -> Void)?
    /// Closure that is called when a child is removed from the root vAtom.
    var onChildRemoved: ((_ vatomID: String) -> Void)?
    
    /// Initialize using a vAtom ID.
    init(vatomID: String) {
        
        self.rootVatomID = vatomID
        
        // move block out of init
        DispatchQueue.main.async {
            self.refresh()
        }
        
    }
    
    /// Refresh the root vAtom's child ID list.
    private func refreshChildIDs() {
        
        BLOCKv.getInventory(id: self.rootVatomID) { [weak self] (vatoms, error) in
            
            // ensure no error
            guard error == nil else {
                printBV(error: "Unable to fetch children. Error: \(error)")
                return
            }
            
            // update the list of child ids
            self?.childVatomIDs = Set(vatoms.map{ $0.id })
            
        }
        
    }
    
    /// Refresh the observes state using remote data.
    public func refresh() {
        self.refreshChildIDs()
    }
    
}
