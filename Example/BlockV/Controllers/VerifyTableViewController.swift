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
//  VerifyTableViewController.swift
//  BlockV_Example
//

import UIKit
import BLOCKv

protocol VerfiyTokenDelegate: class {
    func verifyUserToken(token: UserToken, code: String, completion: @escaping (Bool) -> Void)
    func resendVerification(token: UserToken, completion: @escaping (Bool) -> Void)
}

/// This view controller is responsible for displaying a list of tokens.
///
/// It allows the user to enter or resend a verification code.
class VerifyTableViewController: UITableViewController {
    
    // MARK: - Enums
    
    /// The view controller from which this view controller was presented.
    enum Origin {
        case register // presented from registeration vc
        case profile // presented from profile vc
    }
    
    // MARK: - Outlets
    
    @IBOutlet var nextBarButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    fileprivate let tokenCellID = "cell.token.id"
    
    /// This view controller shows a different set of data based on its presentation origin.
    var origin: Origin!
    
    /// Array of user tokens from registration.
    /// Set on segue to this view controller.
    var registrationTokens: [UserToken] = []
    
    /// Array of all tokens from the `getCurrentUserTokens` call.
    /// Set off the back of the network call.
    fileprivate var allTokens: [FullTokenModel] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        precondition(origin != nil, "This view controller's orgin must be set before loading.")
        
        // check the orgin of presentation
        if origin == .profile {
            
            // remove the 'next' button
            nextBarButton = nil
            
            // fetch all tokens
            fetchAllUserTokens()
        }
        
        self.tableView.reloadData()
        
    }
    
    // MARK: - Networking
    
    /// Fetches all the tokens associated with the user's account. This includes
    /// user tokens and oauth tokens.
    ///
    /// Note: The response contains an array of full token models.
    func fetchAllUserTokens() {
        
        // show loader
        self.showNavBarActivityRight()
        
        BLOCKv.getCurrentUserTokens { [weak self] (fullTokens, error) in
            
            // hide loader
            self?.hideNavBarActivityRight()
            
            // handle error
            guard let model = fullTokens, error == nil else {
                print(">>> Error > Viewer: \(error!.localizedDescription)")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }
            
            // handle success
            print("Viewer > \(model)\n")
            
            // update the tokens
            self?.allTokens = model
            self?.tableView.reloadData()
            
        }
        
    }
    
}

// MARK: - Table view delegate and data source

extension VerifyTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch origin! {
        case .register: return registrationTokens.count
        case .profile: return allTokens.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: tokenCellID, for: indexPath) as! TokenCell
        cell.delegate = self
        
        switch origin! {
        case .register:
            let userToken = registrationTokens[indexPath.row]
            cell.configure(userToken: userToken)
            return cell
        case .profile:
            let fullToken = allTokens[indexPath.row]
            cell.configure(fullToken: fullToken)
            return cell
        }
        
    }
        
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // don't show actions in register flow
        if origin == .register { return [] }
        
        // action to delete the token
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            // get the token
            let token = self.allTokens[indexPath.row]
            // make request
            BLOCKv.deleteCurrentUserToken(token.id) { [weak self] error in
                if let error = error {
                    self?.present(UIAlertController.errorAlert(error), animated: true)
                }
                // refresh local token list
                self?.fetchAllUserTokens()
            }
            
        }
        
        // action to set the token as primary
        let primary = UITableViewRowAction(style: .normal, title: "Primary") { (action, indexPath) in

            // get the token
            let token = self.allTokens[indexPath.row]
            // make request
            BLOCKv.setCurrentUserDefaultToken(token.id) { [weak self] error in
                if let error = error {
                    self?.present(UIAlertController.errorAlert(error), animated: true)
                }
                // refresh local token list
                self?.fetchAllUserTokens()
            }
            
        }
        
        return [delete, primary]
        
    }
    
    /*
     Add this to do the delete locally before going out to network. This will give good feedback locally.
     */
    
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//
//        if editingStyle == .delete {
//
//            // remove the row locally
//
//        }
//
//    }
    
}

extension VerifyTableViewController: VerfiyTokenDelegate {
    
    func verifyUserToken(token: UserToken, code: String, completion: @escaping (Bool) -> Void) {
        
        // show loader
        self.showNavBarActivityRight()
        
        BLOCKv.verifyUserToken(token.value, type: token.type, code: code) {
            [weak self] (userToken, error) in
            
            // hide loader
            self?.hideNavBarActivityRight()
            self?.navigationItem.rightBarButtonItem = self?.nextBarButton
            
            // handle error
            guard let model = userToken, error == nil else {
                print(">>> Error > Viewer: \(error!.localizedDescription)")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                completion(false)
                return
            }
            
            // handle success
            self?.tableView.reloadData()
            self?.present(UIAlertController.okAlert(title: "Info", message: "Token: \(model.value) has been verified."), animated: true)
            
            completion(true)
            print("Viewer > \(model)\n")
        }
    }
    
    func resendVerification(token: UserToken, completion: @escaping (Bool) -> Void) {
        
        // show loader
        self.showNavBarActivityRight()
        
        BLOCKv.resetVerification(forUserToken: token.value, type: token.type) {
            [weak self] (userToken, error) in
            
            // hide loader
            self?.hideNavBarActivityRight()
            self?.navigationItem.rightBarButtonItem = self?.nextBarButton
            
            // handle error
            guard let model = userToken, error == nil else {
                print(">>> Error > Viewer: \(error!.localizedDescription)")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                completion(false)
                return
            }
            
            // handle success
            self?.tableView.reloadData()
            self?.present(UIAlertController.okAlert(title: "Info",
                                                    message: "An verification link/OTP has been sent to your token."),
                          animated: true)
            
            completion(true)
            print("Viewer > \(model)\n")
        }
    }
    
}
