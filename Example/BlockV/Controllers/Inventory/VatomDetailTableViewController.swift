//
//  VatomTableViewController.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import BlockV

/// This view controller demonstrates how to fetch a single vAtom.
///
///
class VatomDetailTableViewController: UITableViewController {
    
    // MARK: - Inputs
    
    /// vAtoms passed in by the presenting view controller.
    var vatom: Vatom!
    
    // MARK: - Properties
    
    fileprivate let dateFormatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Outlets
    
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
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
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

    /// Fetches the input vatom's properties from the Blockv Platform.
    fileprivate func fetchVatom() {
        
        Blockv.getVatoms(withIDs: [vatom.id]) { [weak self] (groupModel, error) in
            
            // end refreshing
            self?.refreshControl?.endRefreshing()
            
            // handle error
            guard error == nil else {
                print("\n>>> Error > Viewer: \(error!.localizedDescription)")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }
            
            // check for our vatom
            guard let newVatom = groupModel?.vatoms.first else {
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
    
}
