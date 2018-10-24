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
//  UserInfoTableViewController.swift
//  BlockV_Example
//

import UIKit
import BLOCKv

class UserInfoTableViewController: UITableViewController {
    
    // MARK: - Enums
    
    /// Represents a table section
    fileprivate enum TableSection: Int {
        case info = 0
    }
    
    // MARK: - Outlets
    
    @IBOutlet var doneButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    ///
    var userModel: UserModel?
    
    fileprivate let titleValueCellId = "cell.profile.id"
    
    /// Dictionary of table view cells for display. Since the number of cells is known and
    /// the count small, we needn't worry about efficiently deque-ing from a reuse pool.
    fileprivate var tableViewCells: [TableSection: [TitleValueCell]] = [:]
    
    // MARK: - Actions
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        updateProfile()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createCells()
        
        self.tableView.register(TitleValueCell.self, forCellReuseIdentifier: titleValueCellId)
        self.tableView.tableFooterView = UIView()
    }
    
    // MARK: - Helpers
    
    /// Creates table view cellls.
    fileprivate func createCells() {
        
        let firstCell = TitleValueCell()
        firstCell.titleLabel.text = "First"
        firstCell.valueTextField.placeholder = "John"
        firstCell.valueTextField.text = userModel?.firstName
        firstCell.valueTextField.keyboardType = .namePhonePad
        firstCell.valueTextField.autocorrectionType = .no
        firstCell.valueTextField.autocapitalizationType = .none
        
        let lastCell = TitleValueCell()
        lastCell.titleLabel.text = "Last"
        lastCell.valueTextField.placeholder = "Appleseed"
        lastCell.valueTextField.text = userModel?.lastName
        lastCell.valueTextField.keyboardType = .namePhonePad
        lastCell.valueTextField.autocorrectionType = .no
        lastCell.valueTextField.autocapitalizationType = .none

        let birthdayCell = TitleValueCell()
        birthdayCell.titleLabel.text = "Birthday"
        birthdayCell.valueTextField.placeholder = "yyyy-MM-dd"
        birthdayCell.valueTextField.text = userModel?.birthday
        birthdayCell.valueTextField.keyboardType = .numbersAndPunctuation
        birthdayCell.valueTextField.autocorrectionType = .no

        // add cells
        tableViewCells[.info] = [firstCell, lastCell, birthdayCell]
        
    }
    
    /// Capture data from table view cells.
    fileprivate func buildForm() -> UserInfo {
        
        let firstCell = tableViewCells[.info]![0]
        let lastCell = tableViewCells[.info]![1]
        let birthdayCell = tableViewCells[.info]![2]
        
        return UserInfo(firstName: firstCell.valueTextField.text,
                                lastName: lastCell.valueTextField.text,
                                birthday: birthdayCell.valueTextField.text)
        
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
            self?.userModel = model
            self?.tableView.reloadData()
            
            // pop back
            self?.navigationController?.popViewController(animated: true)
            
        }
        
    }
    
}

// MARK: - Table view data source

extension UserInfoTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue: section)! {
        case .info: return tableViewCells[.info]!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = TableSection(rawValue: indexPath.section)!
        return tableViewCells[section]![indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! TitleValueCell
        cell.valueTextField.becomeFirstResponder()
    }
    
}
