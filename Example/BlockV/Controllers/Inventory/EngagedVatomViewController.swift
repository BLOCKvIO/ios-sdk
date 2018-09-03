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
 Challenges
 
 - This VC is intended to show the vAtom in 'activated' view mode.
 - I would like for the activated state to be a differenct view controller. However, there must be continuity between
 the Inventory View Controller and the ActivatedViewController.
 - Options:
 1. The ActiavtedVC has a new VatomView and the vatom pack and the fsp are passed in.
 2. The ActivatedVC displays the same VatomView (i.e. has a reference to the VatomView), all that changes is the fsp is
 set to .actiavted. This may be a better solution interms of continuity and in terms of memory.
 
 */

class EngagedVatomViewController: UIViewController {

    // MARK: - Properties
    
    @IBOutlet weak var topVatomView: VatomView! // using storyboards
    @IBOutlet weak var bottomContainerView: UIView! // using code, this is just a container view
    
    private var bottomVatomView: VatomView!
    
    var vatom: VatomModel?
    
    var topProcedure: FaceSelectionProcedure?
    var bottomProcedure: FaceSelectionProcedure?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // VatomView using storyboard
        topVatomView.update(usingVatom: vatom!, procedure: topProcedure!, roster: FaceViewRegistry.shared.roster)
        topVatomView.backgroundColor = .blue
        
        // VatomView built in code
        
        // FIXME: Should we allow VatomView to be init's with no arguments?
        bottomVatomView = VatomView(vatom: vatom!, procedure: bottomProcedure!)
        bottomVatomView.backgroundColor = .red
        bottomContainerView.addSubview(bottomVatomView)
        bottomVatomView.frame = bottomContainerView.bounds.insetBy(dx: 5, dy: 5)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc private func doneTapped() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
