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
//  OutboundActionViewController.swift
//  BlockV_Example
//

import UIKit
import BLOCKv

class OutboundActionViewController: UIViewController {

    // MARK: - Properties

    var vatom: VatomModel!
    var actionName: String!

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
        precondition(actionName != nil, "An action name must be passed into this view controller.")

        self.title = actionName
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
        // execute the action
        performAction(token: token)

    }

    /// Performs the appropriate action using the
    func performAction(token: UserToken) {

        let resultHandler: ((Result<[String: Any], BVError>) -> Void) = { [weak self] result in
            switch result {
            case .success(let json):
                // success
                print("Action response: \(json.debugDescription)")
                self?.hide()
            case .failure(let error):
                print(error.localizedDescription)

                return
            }
        }

        switch actionName {
        case "Transfer":    self.vatom.transfer(toToken: token, completion: resultHandler)
        case "Clone":       self.vatom.clone(toToken: token, completion: resultHandler)
        case "Redeem":      self.vatom.redeem(toToken: token, completion: resultHandler)
        default:
            return
        }

    }

    // MARK: - Helpers

    fileprivate func configureTokenTextField(for type: UserTokenType) {

        switch type {
        case .phone:
            userTokenTextField.keyboardType = .phonePad
            userTokenTextField.placeholder = "Phone number"
            userTokenTextField.autocorrectionType = .no
        case .email:
            userTokenTextField.keyboardType = .emailAddress
            userTokenTextField.placeholder = "Email address"
            userTokenTextField.autocorrectionType = .no
        case .id:
            userTokenTextField.keyboardType = .asciiCapable
            userTokenTextField.placeholder = "User ID"
            userTokenTextField.autocorrectionType = .no
        }
    }

    fileprivate func hide() {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

}
