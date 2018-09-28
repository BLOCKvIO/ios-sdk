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

import UIKit
import BLOCKv

/*
 Goals
 - This VC is intended to show the how to use VatomView to visually display a vAtom.
 - Three VatomViews are shown.
 - Each has a different Face Selection Procedure (FSP).
 */

/// A simple view controller that presents a single vatom using three vatom views.
class TappedVatomViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var vatomViewA: VatomView! // using storyboards
    @IBOutlet weak var vatomViewB: VatomView! // using storyboards
    @IBOutlet weak var containerView: UIView! // using code (container view)
    
    // MARK: - Properties
    
    /// Backing vAtom for display.
    var vatom: VatomModel?
    
    var iconFSP = EmbeddedProcedure.icon.procedure
    var engagedFSP = EmbeddedProcedure.engaged.procedure
    var cardFSP = EmbeddedProcedure.card.procedure
    
    /// VatomView (constructed programmatically)
    let vatomViewC: VatomView = {
        let vatomView = VatomView()
        vatomView.loaderView = CustomLoaderView()
        return vatomView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = vatom?.props.title ?? "--"
        self.descriptionLabel.text = vatom?.props.description ?? "--"
        
        // setup
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        // A - VatomView (via storyboard)
        
        /*
         Here we call `update` in order to pass the vatom and the procedure to the Vatom View.
         This will trigger the Vatom View Life Cycle (VVLC).
         */
        vatomViewA.update(usingVatom: vatom!, procedure: iconFSP)
        
        // B - VatomView (via storyboard)
        
        // Shows passing in a custom loader to this instance of vatom view.
        vatomViewB.loaderView = CustomLoaderView()
        vatomViewB.update(usingVatom: vatom!, procedure: engagedFSP)
        
        // C - VatomView (programmatically)
        
        vatomViewC.update(usingVatom: vatom!, procedure: cardFSP)
        containerView.addSubview(vatomViewC)
        vatomViewC.frame = containerView.bounds
        vatomViewC.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
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
            self?.vatomViewA.update(usingVatom: responseVatom)
            self?.vatomViewB.update(usingVatom: responseVatom)
            self?.vatomViewC.update(usingVatom: responseVatom)

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
