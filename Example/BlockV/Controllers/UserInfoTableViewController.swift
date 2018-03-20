//
//  UserInfoTableViewController.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/10.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import BlockV

class UserInfoTableViewController: UITableViewController {
    
    // MARK: - Enums
    
    /// Represents a table section
    fileprivate enum TableSection: Int {
        case info = 0
        case password
    }
    
    // MARK: - Outlets
    
    @IBOutlet var doneButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    ///
    var userModel: UserModel?
    
    fileprivate let titleValueCellId = "cell.titleValue"
    
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
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        
        let firstCell = tableViewCells[.info]![0]
        let lastCell = tableViewCells[.info]![1]
        let birthdayCell = tableViewCells[.info]![2]
        let passwordCell = tableViewCells[.password]![0]
        
        return UserInfo(firstName: firstCell.valueTextField.text,
                                lastName: lastCell.valueTextField.text,
                                password: passwordCell.valueTextField.text,
                                birthday: birthdayCell.valueTextField.text)
        
    }
    
    /// Performs the network request to update the user's profile information.
    fileprivate func updateProfile() {
        print(#function)
        
        self.showNavBarActivityRight()
        
        let userInfo = buildForm()
        
        Blockv.updateCurrentUser(userInfo) {
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
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue: section)! {
        case .info: return tableViewCells[.info]!.count
        case .password: return tableViewCells[.password]!.count
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
