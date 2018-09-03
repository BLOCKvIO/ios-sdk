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
//  VatomTableViewController.swift
//  BlockV_Example
//

import UIKit
import BLOCKv

/// This view controller demonstrates how to fetch a single vAtom.
///
///
class VatomDetailTableViewController: UITableViewController {
    
    // MARK: - Inputs
    
    /// vAtoms passed in by the presenting view controller.
    var vatom: VatomModel!
    
    // MARK: - Properties
    
    fileprivate let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Outlets
    @IBOutlet weak var actionsButton: UIBarButtonItem!
    
    // info
    @IBOutlet weak var titleValueLabel: UILabel!
    @IBOutlet weak var descriptionValueLabel: UILabel!
    @IBOutlet weak var categoryValueLabel: UILabel!
    @IBOutlet weak var visibilityValueLabel: UILabel!
    @IBOutlet weak var vatomIdValueLabel: UILabel!
    // hierarchy
    @IBOutlet weak var rootTypeValueLabel: UILabel!
    @IBOutlet weak var templateIDLabel: UILabel!
    @IBOutlet weak var templateVariationIDLabel: UILabel!
    @IBOutlet weak var parentIDValueLabel: UILabel!
    // flags
    @IBOutlet weak var acquirableValueLabel: UILabel!
    @IBOutlet weak var redeemableValueLabel: UILabel!
    @IBOutlet weak var tradableValueLabel: UILabel!
    @IBOutlet weak var transferableValueLabel: UILabel!
    @IBOutlet weak var droppedValueLabel: UILabel!
    // meta
    @IBOutlet weak var dateCreatedValueLabel: UILabel!
    @IBOutlet weak var dateModifiedValueLabel: UILabel!
    
    // MARK: - Actions
    
    @IBAction func availableActionsTapped(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "seg.availableActions", sender: self)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        Comment out to reveal the actions button.
        This is not officially supported.
         */
        //self.navigationItem.rightBarButtonItem = nil
        
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        if vatom != nil {
            updateUI()
        }
        
    }
    
    // MARK: - Helpers
    
    @objc
    fileprivate func handleRefresh() {
        fetchVatom()
    }
    
    /// Fetches the input vatom's properties from the BLOCKv platform.
    fileprivate func fetchVatom() {
        
        BLOCKv.getVatoms(withIDs: [vatom.id]) { [weak self] (vatoms, error) in
            
            // end refreshing
            self?.refreshControl?.endRefreshing()
            
            // handle error
            guard error == nil else {
                print("\n>>> Error > Viewer: \(error!.localizedDescription)")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }
            
            // check for our vatom
            guard let newVatom = vatoms.first else {
                let message = "Unable to fetch vAtom with id: \(String(describing: self?.vatom.id))."
                print("\n>>> Warning > \(message)")
                self?.present(UIAlertController.infoAlert(message: message), animated: true)
                return
            }
            
            // handle success
            print("\nViewer > Fetched vAtom:\n\(newVatom)")
            self?.vatom = newVatom
            self?.updateUI()
            
        }
        
    }
    
    /// Updates the static table view cell properties.
    fileprivate func updateUI() {
        
        // info
        titleValueLabel.text          = vatom.title
        descriptionValueLabel.text    = vatom.description
        categoryValueLabel.text       = vatom.category
        visibilityValueLabel.text     = vatom.visibility.type
        vatomIdValueLabel.text        = vatom.id
        // hierarchy
        rootTypeValueLabel.text       = vatom.rootType
        templateIDLabel.text          = vatom.templateID
        templateVariationIDLabel.text = vatom.templateVariationID
        parentIDValueLabel.text       = vatom.parentID
        // flags
        acquirableValueLabel.text     = prettyBool(vatom.isAcquirable)
        redeemableValueLabel.text     = prettyBool(vatom.isRedeemable)
        tradableValueLabel.text       = prettyBool(vatom.isTradeable)
        transferableValueLabel.text   = prettyBool(vatom.isTransferable)
        droppedValueLabel.text        = prettyBool(vatom.isDropped)
        // meta
        dateCreatedValueLabel.text    = dateFormatter.string(from: vatom.whenCreated)
        dateModifiedValueLabel.text   = dateFormatter.string(from: vatom.whenModified)
        
        self.tableView.reloadData()
        
    }
    
    /// Returns "Yes" for `true`, "No" for `false`.
    fileprivate func prettyBool(_ bool: Bool) -> String {
        return bool ? "Yes" : "No"
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let destination = segue.destination as! UINavigationController
        let vc = destination.viewControllers[0] as! ActionListTableViewController
        // pass vatom along
        vc.vatom = self.vatom
        
        
    }
    
    //    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    //        // prevent segue - we will programmatical handle it
    //        return false
    //    }
    
}
