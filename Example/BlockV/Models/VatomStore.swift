//  MIT License
//
//  Copyright (c) 2018 BlockV AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import BLOCKv

/// The `VatomStoreDelegate` protocol defines methods that let you keep track of changes to a vatom-store object.
///
/// Two classes of methods are available: *stable* and *unstable*. Stable methods are only called if the backing
/// region is stable. Unstable methods are called only if the backing region is stable.
protocol VatomStoreDelegate: class {
    
    // * Unstable Methods
    
    /// Tells the delegate when the store changes.
    ///
    /// This method is only called if the backing region is unstable. Typically you would call `reloadData` in response
    /// to this method.
    func onChanged(_ vatomStore: VatomStore)
    
    // * Stable Methods
    
    /// Tells the delegate a vatom was added to the store and provides the index where the vatom was inserted.
    ///
    /// This method is only called if the backing region is stable.
    func vatomStore(_ vatomStore: VatomStore, didAddVatom vatom: VatomModel, at index: Int)
    
    /// Tells the delegate a vatom was removed from the store and provides the index where the vatom was removed.
    ///
    /// This method is only called if the backing region is stable.
    func vatomStore(_ vatomStore: VatomStore, didRemoveVatom vatom: VatomModel, at index: Int)
    
    /// Tells the delegate a vatom was updated and provides the from and to indexes of the move.
    ///
    /// This methods is only called if the backng region is stable.
    func vatomStore(_ vatomStore: VatomStore, didUpdateVatom vatom: VatomModel, moved: (from: Int, to: Int))
    
}

/// A `VatomStore` object monitors a collection of vatoms within an auto-updating region.
///
/// This object makes displaying a collection of vatoms easier by:
/// 1. managing changes to the backing region,
/// 1. abstracting away the complexity in dealing with region destabailzation,
/// 1. allowing sorting, filtering, and grouping, and
/// 1. automatically computing index changes (if the underlying region is stable).
class VatomStore {
    
    /// Backing model of vatoms.
    private(set) var vatoms: [VatomModel] = []
    
    /// Intermediary model used for predicate grouping.
    private(set) var vatomsByPredicate: [String: [VatomModel]] = [:]
    
    weak var delegate: VatomStoreDelegate?
    
    /// Region to monitor.
    private var region: Region
    
    typealias VatomSorter = (_ lhs: VatomModel, _ rhs: VatomModel) -> Bool
    typealias VatomFilter = (_ isIncluded: VatomModel) -> Bool
    
    /// Filter closure used to filter in vatoms which meet the predicate.
    ///
    /// Updating this closure will cause the vatoms to be refitlered.
    /// Defaults to filtering in vatom's at the root inventory.
    var filter: VatomFilter = { $0.props.parentID != "." } {
        didSet { self.replaceVatoms() }
    }
    
    /// Sort closure used to sort vatoms.
    ///
    /// Updating this sort closure will cause the vatoms to be resorted.
    /// Defaults to sorting by the vatom's when-modified date.
    var sorter: VatomSorter = { $0.whenModified > $1.whenModified } {
        didSet { self.replaceVatoms() }
    }
    
    typealias GroupingKeyPath = KeyPath<VatomModel, String>
    
    /// Key path used to group vatoms.
    ///
    /// By specifying a key path, you are informing the store to group vatoms
    var groupingKeyPath: GroupingKeyPath? {
        didSet { self.replaceVatoms() }
    }
    
    // MARK: - Initialization
    
    init(sortedBy sorter: VatomSorter? = nil, filteredBy filter: VatomFilter? = nil) {
        
        // get reference to region
        self.region = DataPool.inventory()
        
        // assign sorter & filter if not nil
        sorter.flatMap { self.sorter = $0 }
        filter.flatMap { self.filter = $0 }
        
        // subscribe to region lifecycle events
        self.region.addObserver(self, selector: #selector(onSyncStarted), name: .synchronizing)
        self.region.addObserver(self, selector: #selector(onStabalized), name: .stabalized)
        self.region.addObserver(self, selector: #selector(onDestabalized), name: .destabalized)
        self.region.addObserver(self, selector: #selector(onChanged), name: .updated)
        
        // only observe at object level if synchronized
        if region.synchronized {
            self.startObjectObservation()
        }
        
        self.replaceVatoms()
    }
    
    /// Adds self as an observer of object-level notifications.
    private func startObjectObservation() {
        // object level
        self.region.addObserver(self, selector: #selector(onObjectUpdated), name: .objectUpdated)
        self.region.addObserver(self, selector: #selector(onObjectAdded), name: .objectAdded)
        self.region.addObserver(self, selector: #selector(onObjectRemoved), name: .objectRemoved)
    }
    
    /// Removes self as an observer of object-level notifications.
    private func stopObjectObservation() {
        // object level
        self.region.removeObserver(self, name: .objectUpdated)
        self.region.removeObserver(self, name: .objectAdded)
        self.region.removeObserver(self, name: .objectRemoved)
    }
    
    /// Resynchronizes the backing region.
    ///
    /// This is an expensive operation and should be called sparingly.
    func synchronize(completion: (() -> Void)? = nil) {
        self.region.forceSynchronize().done {
            completion?()
        }
    }
    
    /// Purges and replaces the stores model with the output of a data pool region query.
    ///
    /// The current filter, sorter and grouping will be applied to the region queury output.
    private func replaceVatoms() {
        
        /*
         TODO: Replace with a diff compute and call the changeSet delegate. This would allow index-based updates when
         the sort or filter closures are updated, and when region-level changes are received while the region is
         unstable.
         */
        
        if let keyPath = groupingKeyPath {
            // create grouped inventory
            createGroupedInventory(withKeyPath: keyPath)
        } else {
            // create inventory
            createInventory()
        }
        // notify delegate vatoms are updated
        self.delegate?.onChanged(self)
    }
    
    /// Creates a filtered and sorted inventory.
    private func createInventory() {
        self.vatoms = (self.region.getAll() as! [VatomModel])
            .filter { self.filter($0) }
            .sorted(by: self.sorter)
    }
    
    /// Creates a filtered, sorted, and grouped inventory.
    ///
    /// Only the 'thumbnail' vatom of each group is added to the vatoms model.
    private func createGroupedInventory(withKeyPath keyPath: GroupingKeyPath) {
        
        // get current inventory and filter
        let inventory = (self.region.getAll() as! [VatomModel])
            .filter { self.filter($0) }
        // group by predicate
        vatomsByPredicate = Dictionary(grouping: inventory, by: { $0[keyPath: groupingKeyPath!] })
        // extract thumbnail vatom from each group
        let thumbnailVatoms = vatomsByPredicate.values.compactMap { $0.sorted(by: sorter).first }
        // sort
        self.vatoms = thumbnailVatoms.sorted(by: sorter)
        
    }
    
    // MARK: - Region Notifications
    
    @objc func onSyncStarted() {
        print(#function)
    }
    
    @objc func onStabalized() {
        print(#function)
        startObjectObservation()
    }
    
    @objc func onDestabalized() {
        print(#function)
        stopObjectObservation()
    }
    
    /// Called when any object in the region changes.
    @objc private func onChanged() {
        
        // only proceed if the region is unstable
        if self.region.synchronized { return }
        
        replaceVatoms() //FIXME: HEAVY
        self.delegate?.onChanged(self)
        
    }
    
    // MARK: - Object Notifications
    
    /// Called when object is added to the region.
    @objc private func onObjectAdded(notification: Notification) {
        
        guard let vatomID = notification.userInfo?["id"] as? String else { return }
        
        // get vatom from data pool
        guard let vatom = findVatom(with: vatomID) else {
            assertionFailure("Logic Error: Vatom should be present.")
            return
        }
        
        // check passes filter
        if !self.filter(vatom) {
            return
        }
        
        // check if grouped
        if let keyPath = groupingKeyPath  {
            add(vatom: vatom, withGroupingKeyPath: keyPath)
        } else {
            add(vatom: vatom)
        }
        
    }
    
    /// Called when an object is removed from the region.
    @objc private func onObjectRemoved(notification: Notification) {
        
        guard let vatomID = notification.userInfo?["id"] as? String else { return }
        
        // check if grouped
        if let keyPath = groupingKeyPath  {
            removeVatom(withID: vatomID, withGroupingKeyPath: keyPath)
        } else {
            removeVatom(withID: vatomID)
        }
        
    }
    
    /// Called when an object is updated in the region.
    @objc private func onObjectUpdated(notification: Notification) {
        
        guard let vatomID = notification.userInfo?["id"] as? String, vatomID != "." else { return }
        guard let updatedVatom = findVatom(with: vatomID) else { return }
        
        if let keyPath = groupingKeyPath {
            update(vatom: updatedVatom, withGroupingKeyPath: keyPath)
        } else {
            update(vatom: updatedVatom)
        }
        
    }
    
    // MARK: Data Pool Helpers
    
    /// Returns the vatom in the region with the specified id.
    private func findVatom(with id: String) -> VatomModel? {
        
        if id == "." { return nil }
        // get vatom and index
        guard let vatom = DataPool.inventory().get(id: id) as? VatomModel else {
            return nil
        }
        return vatom
        
    }
    
}

// MARK: - Extension Ungrouped Changes

extension VatomStore {
    
    private func add(vatom: VatomModel) {
        // find insertion index
        let insertionIndex = self.vatoms.insertionIndexOf(elem: vatom, isOrderedBefore: sorter) //HEAVY
        self.vatoms.insert(vatom, at: insertionIndex)
        self.delegate?.vatomStore(self, didAddVatom: vatom , at: insertionIndex)
    }
    
    private func removeVatom(withID vatomID: String) {
        
        if let index = self.vatoms.firstIndex(where: { $0.id == vatomID }) { // TODO: Search exploiting order
            // remove
            let removeVatom = self.vatoms.remove(at: index)
            self.delegate?.vatomStore(self, didRemoveVatom: removeVatom , at: index)
        }
        
    }
    
    private func update(vatom updatedVatom: VatomModel) {
        
        // find current index
        if let currentIndex = self.vatoms.firstIndex(where: { $0.id == updatedVatom.id }) {
            
            // check passes filter
            if self.filter(updatedVatom) {
                // remove current vatom
                self.vatoms.remove(at: currentIndex)
                // compute insertion index
                let toIndex = self.vatoms.insertionIndexOf(elem: updatedVatom, isOrderedBefore: sorter) // HEAVY
                // insert it
                self.vatoms.insert(updatedVatom, at: toIndex)
                // notify
                self.delegate?.vatomStore(self, didUpdateVatom: updatedVatom,
                                          moved: (from: currentIndex, to: toIndex))
            } else {
                // vatom no longer passes the filter, remove it
                self.vatoms.remove(at: currentIndex)
                self.delegate?.vatomStore(self, didRemoveVatom: updatedVatom, at: currentIndex)
            }
            
        } else {
            
            // re-add if it passes the filter
            if !self.filter(updatedVatom) {
                return
            }
            
            // find insertion index
            let insertionIndex = self.vatoms.insertionIndexOf(elem: updatedVatom, isOrderedBefore: sorter) //HEAVY
            self.vatoms.insert(updatedVatom, at: insertionIndex)
            self.delegate?.vatomStore(self, didAddVatom: updatedVatom , at: insertionIndex)
        }
        
    }
    
}

// MARK: - Extension Grouped Changes

extension VatomStore {
    
    /*
     Notes:
     Grouped changes require adjustments in two places:
     1) `vatomsByPredicate` must be modified to add, remove, or update the vatom.
     2) `vatoms` must be modified to add, remove, or update the thumbnail vatom.
    */
    
    /// Add vatom to predicate group and thumbnail array.
    private func add(vatom: VatomModel, withGroupingKeyPath keyPath: GroupingKeyPath) {
        
        let key = vatom[keyPath: keyPath]
        // check for an existing group
        if self.vatomsByPredicate.index(forKey: key) != nil {
            
            // get vatoms in group
            var groupedVatoms = self.vatomsByPredicate[key]!
            // find where to insert new vatom
            let index = groupedVatoms.insertionIndexOf(elem: vatom, isOrderedBefore: sorter)
            groupedVatoms.insert(vatom, at: index)
            // update the group with the updated array
            self.vatomsByPredicate[key]! = groupedVatoms
            
            // replace the thumbnail
            self.replaceThumbnail(withVatom: groupedVatoms.first!, withGroupingKeyPath: keyPath)
            
        } else {
            // no group, create group and add vatom
            self.vatomsByPredicate[key] = [vatom]
            add(vatom: vatom)
        }
    }
    
    /// Remove vatom from predicate group and thumbnail array.
    private func removeVatom(withID vatomID: String, withGroupingKeyPath keyPath: GroupingKeyPath) {
        
        /*
         TODO: If the key could be determined at this point (which requires the remove vatom payload), finding the
         group would be efficient. The line below is inefficient as the groups must be traversed.
         */

        // find the group containing the to be removed vatom
        guard let groupedVatoms = self.vatomsByPredicate.first(where: {
            $1.contains(where: { $0.id == vatomID }) //HEAVY
        }) else {
            return
        }
        
        let key = groupedVatoms.key
        
        /*
         Notes:
         If a group has a single vatom, the entire group must be removed.
         If the group has more than one vatom, the vatom must be removed, the group's thumbnial replaced, and the
         vatom array updated.
         */
        
        // check if we are removing the thumbnail
        if groupedVatoms.value.count == 1 {
            // remove the key-value group
            self.vatomsByPredicate.removeValue(forKey: key)
            // remove vatom
            self.removeVatom(withID: vatomID)
        } else {
            // remove vatom from group
            self.vatomsByPredicate[key]!.removeAll(where: { $0.id == vatomID })
            // replace the thumbnail
            self.replaceThumbnail(withVatom: groupedVatoms.value.first!, withGroupingKeyPath: keyPath)
        }
        
    }
    
    /// Update vatom in predicate group and thumbnail array.
    private func update(vatom updatedVatom: VatomModel, withGroupingKeyPath keyPath: GroupingKeyPath) {
        
        let key = updatedVatom[keyPath: keyPath]
        
        // check passes filter
        if self.filter(updatedVatom) {
            
            // check for existng group
            if var groupedVatoms = self.vatomsByPredicate[key] {
                
                // remove vatom
                groupedVatoms.removeAll(where: { $0.id == updatedVatom.id })
                // find where to insert new vatom
                let index = groupedVatoms.insertionIndexOf(elem: updatedVatom, isOrderedBefore: sorter)
                groupedVatoms.insert(updatedVatom, at: index)
                // update the group with the updated array
                self.vatomsByPredicate[key]! = groupedVatoms
                
                // replace the thumbnail
                self.replaceThumbnail(withVatom: groupedVatoms.first!, withGroupingKeyPath: keyPath)
                
            } else {
                // add vatom
                self.add(vatom: updatedVatom, withGroupingKeyPath: keyPath)
            }
            
        } else {
            // remove (no longer passes filter)
            self.removeVatom(withID: updatedVatom.id, withGroupingKeyPath: keyPath)
            //FIXME: The vatom is known, rather pass the resolved key path to avoid heavy computation.

        }
        
    }
    
    /// Replaces the vatoms array thumbnail and notifies the delegate of the update.
    private func replaceThumbnail(withVatom thumbnailVatom: VatomModel, withGroupingKeyPath keyPath: GroupingKeyPath) {
        // find the grouping key
        let key = thumbnailVatom[keyPath: keyPath]
        // index of old thumbnail
        if let fromIndex = self.vatoms.firstIndex(where: { $0[keyPath: keyPath] == key }) {
            // remove old thumbnail
            self.vatoms.remove(at: fromIndex)
            // compute index of new thumbnail
            let toIndex = self.vatoms.insertionIndexOf(elem: thumbnailVatom, isOrderedBefore: sorter)
            // insert
            self.vatoms.insert(thumbnailVatom, at: toIndex)
            // notify update to thumbnail vatom
            self.delegate?.vatomStore(self, didUpdateVatom: thumbnailVatom, moved: (fromIndex, toIndex))
        }
        
    }

}
