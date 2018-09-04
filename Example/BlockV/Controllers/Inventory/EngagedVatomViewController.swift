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

    // MARK: - Properties
    
    @IBOutlet weak var topVatomView: VatomView! // using storyboards
    @IBOutlet weak var bottomContainerView: UIView! // using code, this is just a container view
    
    private var bottomVatomView: VatomView!
    
    /// Backing vAtom for display.
    var vatom: VatomModel?
    
    var topProcedure: FaceSelectionProcedure?
    var bottomProcedure: FaceSelectionProcedure?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup
        self.title = "Vatom View"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        // top - VatomView via storyboard
        topVatomView.update(usingVatom: vatom!, procedure: topProcedure!, roster: FaceViewRegistry.shared.roster)
        topVatomView.backgroundColor = .blue
        
        // bottom - VatomView programmatically
        bottomVatomView = VatomView(vatom: vatom!, procedure: bottomProcedure!)
        bottomVatomView.backgroundColor = .red
        bottomContainerView.addSubview(bottomVatomView)
        bottomVatomView.frame = bottomContainerView.bounds.insetBy(dx: 15, dy: 15)
        
    }
    
    // MARK: - Actions
    
    @objc private func doneTapped() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seg.vatom.detail" {
            let destination = segue.destination as! VatomDetailTableViewController
            //destination.vatom = vatomToPass
        }
    }

}
