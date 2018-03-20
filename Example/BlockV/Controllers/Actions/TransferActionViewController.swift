//
//  TransferActionViewController.swift
//  BlockV_Example
//

import UIKit
import BlockV

class TransferActionViewController: UIViewController {
    
    // MARK: - Properties
    
    var vatom: Vatom!

    @IBOutlet weak var destinationTokenTextField: UITextField!
    
    // MARK: - Outlets
    
    @IBOutlet weak var userTokenSegmentedControl: UISegmentedControl!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        precondition(vatom != nil, "A vAtom must be passed into this view controller.")
        
    }
    
    // MARK: - Actions

    @IBAction func performActionTapped(_ sender: Any) {
        
        guard let token = destinationTokenTextField.text else { return }
        
        /*
         Use the vAtoms convenience transfer method to transfer the vAtom to
         a another user via a phone, email, or user id token.
         */
        
        self.vatom.transfer(toToken: token, type: .email) { [weak self] (data, error) in
           
            // unwrap data, handle error
            guard let data = data, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // success
            print("Reactor response: \(String.init(data: data, encoding: .utf8))")
            self?.hide()
        }
        
    }
    
    fileprivate func hide() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
