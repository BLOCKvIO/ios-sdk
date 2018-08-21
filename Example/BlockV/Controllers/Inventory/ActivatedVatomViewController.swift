//
//  ActivatedVatomViewController.swift
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

class ActivatedVatomViewController: UIViewController {

    // MARK: - Properties
    
    var vatomPack: VatomPackModel?
    var procedure: EmbeddedProcedure?
    
    @IBOutlet weak var vatomView: VatomView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
