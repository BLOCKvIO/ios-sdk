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
//  RegisterTableViewController.swift
//  BlockV_Example
//

import UIKit
import BLOCKv


class RegisterTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var doneButton: UIBarButtonItem!
    
    // MARK: - Enums
    
    fileprivate enum TableSection: Int {
        case info = 0
        case tokens
    }
    
    // MARK: - Properties
    
    fileprivate let titleValueCellId = "cell.input.id"
    
    /// Array of user tokens for registration
    fileprivate var userTokens: [UserToken] = []
    
    /// Dictionary of table view cells for display. Since the number of cells is known and
    /// the count small, we needn't worry about efficiently deque-ing from a reuse pool.
    fileprivate var tableViewCells: [TableSection: [TitleValueCell]] = [:]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create input form cells
        createCells()
        
        self.tableView.register(TitleValueCell.self, forCellReuseIdentifier: titleValueCellId)
        self.tableView.rowHeight = 44
        
    }
    
    // MARK: - Helpers
    
    /// Creates table view cellls.
    fileprivate func createCells() {
        
        let firstCell = TitleValueCell()
        firstCell.titleLabel.text = "First"
        firstCell.valueTextField.placeholder = "John"
        firstCell.valueTextField.keyboardType = .namePhonePad
        firstCell.valueTextField.autocorrectionType = .no
        firstCell.valueTextField.autocapitalizationType = .none
        
        let lastCell = TitleValueCell()
        lastCell.titleLabel.text = "Last"
        lastCell.valueTextField.placeholder = "Appleseed"
        lastCell.valueTextField.keyboardType = .namePhonePad
        lastCell.valueTextField.autocorrectionType = .no
        lastCell.valueTextField.autocapitalizationType = .none
        
        let passwordCell = TitleValueCell()
        passwordCell.titleLabel.text = "Password"
        passwordCell.valueTextField.placeholder = "******"
        passwordCell.valueTextField.keyboardType = .default
        passwordCell.valueTextField.autocorrectionType = .no
        passwordCell.valueTextField.autocapitalizationType = .none
        
        // add cells
        tableViewCells[.info] = [firstCell, lastCell, passwordCell]
        
        let phoneCell = TitleValueCell()
        phoneCell.titleLabel.text = "Phone"
        phoneCell.valueTextField.placeholder = "Phone"
        phoneCell.valueTextField.keyboardType = .phonePad
        phoneCell.valueTextField.autocorrectionType = .no
        phoneCell.valueTextField.autocapitalizationType = .none
        
        let emailCell = TitleValueCell()
        emailCell.titleLabel.text = "Email"
        emailCell.valueTextField.placeholder = "Email"
        emailCell.valueTextField.keyboardType = .emailAddress
        emailCell.valueTextField.autocorrectionType = .no
        emailCell.valueTextField.autocapitalizationType = .none
        
        // add cells
        tableViewCells[.tokens] = [phoneCell, emailCell]
        
    }
    
    /// Capture data from table view cells.
    fileprivate func buildForm() -> (UserInfo, [UserToken]) {
        
        // user info
        let firstCell = tableViewCells[.info]![0]
        let lastCell = tableViewCells[.info]![1]
        let passwordCell = tableViewCells[.info]![2]
        
        let userInfo = UserInfo(firstName: firstCell.valueTextField.text,
                                lastName: lastCell.valueTextField.text,
                                password: passwordCell.valueTextField.text)
        
        // tokens
        let phoneCell = tableViewCells[.tokens]![0]
        let emailCell = tableViewCells[.tokens]![1]
        
        var tokens = [UserToken]()
        if let tokenValue = phoneCell.valueTextField.text, !tokenValue.isEmpty {
            let phoneToken = UserToken(value: tokenValue, type: .phone)
            tokens.append(phoneToken)
        }
        if let tokenValue = emailCell.valueTextField.text, !tokenValue.isEmpty {
            let emailToken = UserToken(value: tokenValue, type: .email)
            tokens.append(emailToken)
        }
        
        return (userInfo, tokens)
        
    }
    
    // MARK: - Actions
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        print(#function)
        
        // show loader
        self.showNavBarActivityRight()
        
        // extract data from form
        let (userInfo, tokens) = buildForm()
        self.userTokens = tokens
        
        guard !userTokens.isEmpty else {
            present(UIAlertController.okAlert(title: "Info",
                                              message: "Client Validation: At least one token must be supplied for registration."),
                    animated: true, completion: nil)
            return
        }
        
        /// Register a user with multiple tokens
        BLOCKv.register(tokens: tokens, userInfo: userInfo) {
            [weak self] (userModel, error) in
            
            // hide loader
            self?.hideNavBarActivityRight()
            self?.navigationItem.setRightBarButton(self!.doneButton, animated: true)
            
            // handle error
            guard let model = userModel, error == nil else {
                print(">>> Error > Viewer: \(error!.localizedDescription)")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }
            
            // handle success
            print("Viewer > \(model)\n")
            self?.performSegue(withIdentifier: "seg.register.done", sender: self)
            
        }
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seg.register.done" {
            if let vc = segue.destination as? VerifyTableViewController {
                vc.origin = .register
                vc.registrationTokens = self.userTokens
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // prevent the segue - we will do it programatically
        return false
    }
    
}

// MARK: - Table view data source

extension RegisterTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue: section)! {
        case .info: return 3
        case .tokens: return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = TableSection(rawValue: indexPath.section)!
        return tableViewCells[section]![indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch TableSection(rawValue: section)! {
        case .info: return "General"
        case .tokens: return "Tokens"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)! as! TitleValueCell
        cell.valueTextField.becomeFirstResponder()
    }
    
}
