//
//  VerifyTableViewController.swift
//  BlockV_Example
//

import UIKit
import BlockV

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
        
        Blockv.getCurrentUserTokens { [weak self] (fullTokens, error) in
            
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

// MARK: - Table view data source

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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell.token.id", for: indexPath) as! TokenCell
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
    
}

extension VerifyTableViewController: VerfiyTokenDelegate {
    
    func verifyUserToken(token: UserToken, code: String, completion: @escaping (Bool) -> Void) {
        
        // show loader
        self.showNavBarActivityRight()
        
        Blockv.verifyUserToken(token.value, type: token.type, code: code) {
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
        
        Blockv.resetVerification(forUserToken: token.value, type: token.type) {
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
