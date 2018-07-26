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

//
//  InventoryCollectionViewController.swift
//  BlockV_Example
//

import UIKit
import BLOCKv

/// This view controller demonstrates how to fetch the current user's inventory.
///
/// This example only shows the Activated Image of each vAtom. In future releases
/// vAtom Face Code will be added to this example.
class InventoryCollectionViewController: UICollectionViewController {
    
    // MARK: - Properties
    
    fileprivate lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return control
    }()
    
    /// Model holding the inventory vatoms.
    fileprivate var vatoms: [VatomModel] = [] {
        didSet {
            filteredVatoms = vatoms.filter {
                // filter out: dropped, avatar, and coin wallet vatoms
                (!$0.isDropped)
                    && (!$0.templateID.hasSuffix("::vAtom::Avatar"))
                    && (!$0.templateID.hasSuffix("::vAtom::CoinWallet"))
            }
        }
    }
    
    /// Model holding the filtered vAtoms.
    fileprivate var filteredVatoms: [VatomModel] = [] {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    /// vAtom to pass to detail view controller.
    fileprivate var vatomToPass: VatomModel?
    
    /// Dictionary mapping vatom IDs to image data (activated image).
    fileprivate var activatedImages = [String : Data]()
    
    /// Download queue to manage concurrently downloading each vAtom's Activated Image.
    ///
    /// The host app is responsible for downloading and managing the association between the
    /// vAtom and its Activated Image resource.
    ///
    /// Since many vAtoms share resources, a futher optimization would be made to check if
    /// the same resource is being requested, and if so, return a cached version. However,
    /// this is beyond the scope of this example app.
    fileprivate lazy var downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2 // limit concurrent downloads
        return queue
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView?.refreshControl = self.refreshControl
        self.fetchInventory()
        //self.performDiscoverQuery()
        
        // connect and subscribe to update stream
        self.subscribeToUpdateStream()
    }
    
    deinit {
        self.downloadQueue.cancelAllOperations()
    }
    
    // MARK: - Helpers
    
    /// This method shows a few examples of subscribing to events from the update stream.
    private func subscribeToUpdateStream() {
        
        // MARK: - Web Socket Lifecycle
        
        BLOCKv.socket.connect()
        
        BLOCKv.socket.onConnected.subscribe(with: self) {
            print("\nViewer > Web socket - Connected")
        }
        
        BLOCKv.socket.onDisconnected.subscribe(with: self) { _ in
            print("\nViewer > Web socket - Disconnected")
        }
        
        // MARK: - Inventory
        
        // subscribe to inventory update events
        BLOCKv.socket.onInventoryUpdate.subscribe(with: self) { inventoryEvent in
            
            print("\nViewer > Inventory Update Event: \n\(inventoryEvent)")
            
            /*
             Typically you would perfrom a localized update using the info inside of the event.
             Refreshing the inventory off the back of the Web socket event is inefficient.
             */
            
            // refresh inventory
            self.fetchInventory()
            
        }
        
        // MARK: - State Update
        
        // subscribe to vatom state update events
        BLOCKv.socket.onVatomStateUpdate.subscribe(with: self) { vatomStateEvent in
            
            print("\nViewer > State Update Event: \n\(vatomStateEvent)")
            
            /*
             Typically you would perfrom a localized update using the info inside of the event.
             Refreshing the inventory off the back of the Web socket event is inefficient.
             */
            
            // refresh inventory
            self.fetchInventory()
            
            // example of extracting some bool value
            if let isDropped = vatomStateEvent.vatomProperties["vAtom::vAtomType"]?["dropped"]?.boolValue {
                print("\nViewer > State Update - isDropped \(isDropped)")
            }
            
            // example of extracting array of float values
            if let coordinates = vatomStateEvent.vatomProperties["vAtom::vAtomType"]?["geo_pos"]?["coordinates"]?.arrayValue?.compactMap({ $0.floatValue }) {
                print("\nViewer > State Update - vAtom coordinates: \(coordinates)")
            }
            
        }
        
        // subcribe to vatom state updates (where the event was either a drop or pick-up)
        BLOCKv.socket.onVatomStateUpdate.subscribe(with: self) { vatomStateEvent in
            
            print("\nViewer > State Update - Filters in only Drop/Pick-Up events")
            
            }.filter {
                // check the properties for the 'dropped' flag.
                $0.vatomProperties.contains(where: { $0.key == "dropped" })
        }
        
        // MARK: - Activity
        
        // subcribe to an activity event
        BLOCKv.socket.onActivityUpdate.subscribe(with: self) { activityEvent in
            
            print("\nViewer > Activity Event: \n\(activityEvent)")
            
        }
        
    }
    
    /// Fetches the current user's inventory.
    ///
    /// Fetches all the vatom's within the current user's inventory.
    /// Note: Input parameters are left to their defautls.
    fileprivate func fetchInventory() {
        
        BLOCKv.getInventory { [weak self] (packModel, error) in
            
            // handle error
            guard let model = packModel, error == nil else {
                print("\n>>> Error > Viewer: \(error!.localizedDescription)")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }
            
            // handle success
            print("\nViewer > Fetched inventory PackModel")
            
            /*
             NOTE
             
             It is sometimes useful to order vAtoms by their `whenModified` date. This will
             ensure new vAtoms appear at the top of the user's inventory.
             
             Additionally, if a vAtom's state changes on the BLOCKv platform so to will its
             `whenModifed` date. For example, if a vAtom is picked up off the map, its
             `droppped` flag is set as `false` and the `whenModified` date updated.
             */
            self?.vatoms = model.vatoms.sorted { $0.whenModified > $1.whenModified }
            
            // begin download
            self?.dowloadActivatedImages()
            
        }
        
    }
    
    /// Fetched the current user's inventory using the discover call.
    ///
    /// This demonstrates the use of the discover call.
    fileprivate func performDiscoverQuery() {
        
        // create a discover query builder
        let builder = DiscoverQueryBuilder()
        builder.setScopeToOwner()
        builder.addDefinedFilter(forField: .templateID, filterOperator: .equal, value: "vatomic.prototyping::DrinkCoupon::v1", combineOperator: .and)
        
        // execute the discover call
        BLOCKv.discover(builder) { [weak self] (packModel, error) in
            
            // handle error
            guard let model = packModel, error == nil else {
                print("\n>>> Error > Viewer: \(error!.localizedDescription)")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }
            
            // handle success
            print("\nViewer > Fetched discover group model")
            print("\n\(model)")
            
        }
        
    }
    
    /// Creates a data download operation for each vatom's activated image and adds it to our download queue.
    ///
    /// On completion of the download, the data blob is mapped to the vatom ID in a dictionary.
    func dowloadActivatedImages() {
        
        for vatom in filteredVatoms {
            
            // find the vatom's activated image url
            guard let activatedImageURL = vatom.resources.first(where: { $0.name == "ActivatedImage"} )?.url else {
                // oops, not found, skip this vatom
                continue
            }
            
            // encode the url
            guard let encodedURL = try? BLOCKv.encodeURL(activatedImageURL) else {
                continue
            }
            
            // create network operation
            let operation = NetworkDataOperation(urlString: encodedURL.absoluteString) { [weak self] (data, error) in
                
                // unwrap data, handle error
                guard let data = data, error == nil else {
                    print("\n>>> Error > Viewer: \(error!.localizedDescription)")
                    return
                }
                
                // handle success
                
                // store the image data
                self?.activatedImages[vatom.id] = data
                
                // handle success
                print("Viewer > Downloaded 'ActivatedImage' for vAtom: \(vatom.id) Data: \(data)")
                
                // find the vatoms index
                if let index = self?.filteredVatoms.index(where: { $0.id == vatom.id }) {
                    // ask collection view to reload that cell
                    self?.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
                }
                
            }
            
            // add the operation to the download queue
            downloadQueue.addOperation(operation)
        }
        
    }
    
    @objc
    fileprivate func handleRefresh() {
        print(#function)
        fetchInventory()
        self.refreshControl.endRefreshing()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seg.vatom.detail" {
            let destination = segue.destination as! VatomDetailTableViewController
            destination.vatom = vatomToPass
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // prevent the segue - we will do it programatically
        if identifier == "seg.vatom.detail" {
            return false
        }
        return true
    }
    
}

extension InventoryCollectionViewController {
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filteredVatoms.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VatomCell.reuseIdentifier, for: indexPath) as! VatomCell
        
        cell.backgroundColor = UIColor.gray.withAlphaComponent(0.1)
        
        // get vatom id
        let vatomID = filteredVatoms[indexPath.row].id
        
        // set the cell's vatom
        cell.vatom = filteredVatoms[indexPath.row]

        // find image data
        if let imageData = activatedImages[vatomID] {
            cell.contentView.alpha = 0.2
            cell.activatedImageView.image = UIImage.init(data: imageData)
            cell.contentView.alphaIn()
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // get the vatom to pass
        let currentCell = collectionView.cellForItem(at: indexPath) as! VatomCell
        // check if the cell has a vatom
        if let vatom = currentCell.vatom {
            self.vatomToPass = vatom
            performSegue(withIdentifier: "seg.vatom.detail", sender: self)
        }
        
    }

}

extension InventoryCollectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // Two columns
        let padding: CGFloat =  36 // based on section insets (see storybard)
        let collectionViewSize = collectionView.frame.size.width - padding
        return CGSize(width: collectionViewSize/2, height: collectionViewSize/2)
    }
    
}
