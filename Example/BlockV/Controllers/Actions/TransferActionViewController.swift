//
//  TransferActionViewController.swift
//  BlockV_Example
//

import UIKit
import BlockV

class TransferActionViewController: UIViewController {
    
    // MARK: - Properties
    
    var vatom: Vatom!
    
    /// Type of token selected.
    var tokenType: UserTokenType {
        get {
            switch tokenTypeSegmentedControl.selectedSegmentIndex {
            case 0: return .phone
            case 1: return .email
            default: fatalError("Unhandled index.")
            }
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var tokenTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var userTokenTextField: UITextField!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        precondition(vatom != nil, "A vAtom must be passed into this view controller.")
        
    }
    
    // MARK: - Actions
    
    @IBAction func tokenTypeSegmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: configureTokenTextField(for: .phone)
        case 1: configureTokenTextField(for: .email)
        case 2: configureTokenTextField(for: .id)
        default: fatalError("Unhandled index.")
        }
        self.userTokenTextField.becomeFirstResponder()
    }
    
    @IBAction func performActionTapped(_ sender: Any) {
        
        guard let token = userTokenTextField.text else { return }
        
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
            print("Action response: \(String.init(data: data, encoding: .utf8))")
            self?.hide()
        }
        
    }
    
    // TESTING ONLY
    
    @IBAction func dropTapped(_ sender: Any) {
        
        self.vatom.drop(latitude: -50.0, longitude: -50.0) { (data, error) in
            
            // unwrap data, handle error
            guard let data = data, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // success
            print("Action response: \(String.init(data: data, encoding: .utf8))")
            
        }
    }
    
    @IBAction func pickupTapped(_ sender: Any) {
        
        self.vatom.pickUp { (data, error) in
            
            // unwrap data, handle error
            guard let data = data, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // success
            print("Action response: \(String.init(data: data, encoding: .utf8))")
            
        }
    }
    
    // TESTING ONLY
    
    // MARK: - Helpers
    
    fileprivate func configureTokenTextField(for type: UserTokenType) {
        
        switch type {
        case .phone:
            userTokenTextField.keyboardType = .phonePad
            userTokenTextField.placeholder = "Phone number"
        case .email:
            userTokenTextField.keyboardType = .emailAddress
            userTokenTextField.placeholder = "Email address"
        case .id:
            userTokenTextField.keyboardType = .asciiCapable
            userTokenTextField.placeholder = "User ID"
        }
    }
    
    fileprivate func hide() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
