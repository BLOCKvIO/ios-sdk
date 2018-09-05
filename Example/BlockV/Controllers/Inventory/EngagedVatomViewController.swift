//
//  EngagedVatomViewController.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/08/21.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import BLOCKv

/*
 Goals
 - This VC is intended to show the how to use VatomView to visually display a vAtom.
 - Three view are shown each presenting a VatomView.
 - Each Vatom View has a different Face Selection Procedure (FSP).
 */

class EngagedVatomViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var topVatomView: VatomView! // using storyboards
    @IBOutlet weak var middleVatomView: VatomView! // using storyboards
    @IBOutlet weak var bottomContainerView: UIView! // using code, this is just a container view
    
    // MARK: - Properties
    
    private var bottomVatomView: VatomView!
    
    /// Backing vAtom for display.
    var vatom: VatomModel? {
        didSet {
            print("Vatom Updated: \(vatom?.id ?? "nil")")
        }
    }
    
    var topFSP: FaceSelectionProcedure    = EmbeddedProcedure.card.procedure
    var middleFSP: FaceSelectionProcedure = EmbeddedProcedure.card.procedure
    var bottomFSP: FaceSelectionProcedure = EmbeddedProcedure.card.procedure
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = vatom?.title ?? "--"
        self.descriptionLabel.text = vatom?.description ?? "--"
        
        // setup
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        // top - VatomView via storyboard
        // here we must call `update` in order to pass the vatom and the procedure to the VV. The default roster
        // will be used.
        topVatomView.update(usingVatom: vatom!, procedure: topFSP)
        
        // middle - VatomView via storyboard
        middleVatomView.update(usingVatom: vatom!, procedure: middleFSP)
        
        // bottom - VatomView programmatically
        bottomVatomView = VatomView(vatom: vatom!, procedure: bottomFSP)
        bottomContainerView.addSubview(bottomVatomView)
        bottomVatomView.frame = bottomContainerView.bounds
        bottomVatomView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
    }
    
    // MARK: - Actions

    /// Refresh the vAtom's state. Go out to network to fetch the lastest vAtoms state.
    @IBAction func handleRefresh(_ sender: UIBarButtonItem) {
        print(#function)

        // refresh the vatom
        BLOCKv.getVatoms(withIDs: [vatom!.id]) { [weak self] (responseVatom, error) in

            // handle error
            guard error == nil else {
                print("\n>>> Error > Viewer: \(error!.localizedDescription)")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }

            // ensure a vatom was returned
            guard let responseVatom = responseVatom.first else {
                print("\n>>> Error > Viewer: No vAtom found")
                return
            }
            
            self?.vatom = responseVatom
            
            // update the vatom view
            self?.topVatomView.update(usingVatom: responseVatom)
            

        }
        
        
    }
    
    @objc private func doneTapped() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seg.vatom.detail" {
            let destination = segue.destination as! VatomDetailTableViewController
            destination.vatom = vatom
        }
    }

}
