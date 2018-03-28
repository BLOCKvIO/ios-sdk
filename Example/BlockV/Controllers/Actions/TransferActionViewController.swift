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
//  TransferActionViewController.swift
//  BlockV_Example
//

import UIKit
import BLOCKv

class TransferActionViewController: UIViewController {
    
    // MARK: - Properties
    
    var vatom: Vatom!
    
    /// Type of token selected.
    var tokenType: UserTokenType {
        get {
            switch tokenTypeSegmentedControl.selectedSegmentIndex {
            case 0: return .phone
            case 1: return .email
            case 2: return .id
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
        
        // create the token
        guard let value = userTokenTextField.text else { return }
        let token = UserToken(value: value, type: tokenType)
        
        performTransferManual(token: token)
        // OR
        //performTransferConvenience(token: token)
        
    }
    
    /// Option 1 - This show the convenience `transfer` method on Vatom to transfer the vAtom to
    /// a another user via a phone, email, or user id token.
    func performTransferConvenience(token: UserToken) {
        
        self.vatom.transfer(toToken: token) { [weak self] (data, error) in
            
            // unwrap data, handle error
            guard let data = data, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // success
            print("Action response: \(String.init(data: data, encoding: .utf8) ?? "<parsing error>")")
            self?.hide()
        }
        
    }
    
    /// Option 2 - This show the manual, method of performing an action by constructing the
    /// action body payload.
    func performTransferManual(token: UserToken) {
        
        /*
         Each action has a defined payload structure.
        */
        let body = [
            "this.id": self.vatom.id,
            "new.owner.\(token.type.rawValue)": token.value
        ]
        
        BLOCKv.performAction(name: "Transfer", payload: body) { [weak self] (data, error) in
            
            // unwrap data, handle error
            guard let data = data, error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            // success
            print("Action response: \(String.init(data: data, encoding: .utf8) ?? "<parsing error>")")
            self?.hide()
            
        }
        
    }

    
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
