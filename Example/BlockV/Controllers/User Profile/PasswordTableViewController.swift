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
//  PasswordTableViewController.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/24.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import BLOCKv

class PasswordTableViewController: UITableViewController {
    
    // MARK: - Enums
    
    /// Represents a table section
    fileprivate enum TableSection: Int {
        case password = 0
    }
    
    // MARK: - Outlets
    
    @IBOutlet var doneButton: UIBarButtonItem!
    
    // MARK: - Actions
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        updateProfile()
    }
    
    // MARK: - Properties
    
    fileprivate let titleValueCellId = "cell.profile.id"
    
    /// Dictionary of table view cells for display. Since the number of cells is known and
    /// the count small, we needn't worry about efficiently deque-ing from a reuse pool.
    fileprivate var tableViewCells: [TableSection: [TitleValueCell]] = [:]
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // add cells to tableview
        createCells()
    }
    
    // MARK: - Helpers
    
    /// Creates table view cellls.
    fileprivate func createCells() {
        
        let passwordCell = TitleValueCell()
        passwordCell.titleLabel.text = "Password"
        passwordCell.valueTextField.placeholder = "******"
        passwordCell.valueTextField.keyboardType = .default
        passwordCell.valueTextField.autocorrectionType = .no
        passwordCell.valueTextField.autocapitalizationType = .none
        
        // add cells
        tableViewCells[.password] = [passwordCell]
        
    }

    /// Capture data from table view cells.
    fileprivate func buildForm() -> UserInfo {

        let passwordCell = tableViewCells[.password]![0]
        
        return UserInfo(password: passwordCell.valueTextField.text)
        
    }
    
    /// Performs the network request to update the user's profile information.
    fileprivate func updateProfile() {
        print(#function)
        
        self.showNavBarActivityRight()
        
        let userInfo = buildForm()
        
        BLOCKv.updateCurrentUser(userInfo) {
            [weak self] (userModel, error) in
            
            // reset nav bar
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
            
            // update the model
            self?.tableView.reloadData()
            
            // pop back
            self?.navigationController?.popViewController(animated: true)
            
        }
        
    }
    
}

// MARK: - Table view data source

extension PasswordTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue: section)! {
        case .password: return tableViewCells[.password]!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> TitleValueCell {
        let section = TableSection(rawValue: indexPath.section)!
        return tableViewCells[section]![indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! TitleValueCell
        cell.valueTextField.becomeFirstResponder()
    }
    
}
