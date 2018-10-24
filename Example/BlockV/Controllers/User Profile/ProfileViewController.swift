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
//  ProfileViewController.swift
//  BlockV_Example
//

import UIKit
import BLOCKv
import Alamofire

class ProfileViewController: UITableViewController {
    
    // MARK: - Enums
    
    fileprivate enum TableSection: Int {
        case general = 0
        case logout
    }
    
    /// Models the state of avatar upload activity.
    fileprivate enum UploadNetworkState {
        case none
        case busy
    }
    
    // MARK: - Properties
    
    fileprivate var userModel: UserModel?
    
    fileprivate lazy var picker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        return picker
    }()
    
    fileprivate let manager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        //configuration.urlCache = nil // disable cache
        return Alamofire.SessionManager(configuration: configuration)
    }()
    
    /// Computes a nice display name.
    fileprivate var displayName: String {
        get {
            var name = ""
            if let first = userModel?.firstName {
                name += first
            }
            if let last = userModel?.lastName {
                name += " \(last)"
            }
            return name.isEmpty ? "First Last Name" : name
        }
    }
    
    fileprivate var uploadState: UploadNetworkState = .none {
        didSet {
            switch uploadState {
            case .none:
                self.uploadProgressView.setProgress(0, animated: false)
                self.uploadProgressView.alphaOut()
            case .busy:
                self.uploadProgressView.setProgress(0, animated: false)
                self.uploadProgressView.alphaIn()
            }
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var avatarContainerView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    @IBOutlet weak var versionLabel: UILabel!
    
    // MARK: - Actions
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add tap gestrue
        let tap = UITapGestureRecognizer(target: self, action: #selector(presentImagePicker))
        avatarContainerView.addGestureRecognizer(tap)
        
        refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        // ui polish
        uploadState = .none
        avatarImageView.contentMode = .scaleAspectFill
        versionLabel.text = versionString()
        
        // fetch profile
        fetchUserProfile()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // this will ensure a refresh each time the vc appears
        fetchUserProfile()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarContainerView.layer.cornerRadius = avatarContainerView.frame.size.height / 2
        avatarContainerView.clipsToBounds = true
    }
    
    // MARK: - Helpers
    
    @objc
    fileprivate func handleRefresh() {
        print(#function)
        fetchUserProfile()
    }
    
    /// Fetches the user's profile information.
    fileprivate func fetchUserProfile() {
        
        BLOCKv.getCurrentUser { [weak self] (userModel, error) in
            
            // end refreshing
            self?.refreshControl?.endRefreshing()

            // handle error
            guard let model = userModel, error == nil else {
                print(">>> Error > Viewer: \(error!.localizedDescription)\n")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }
            
            // handle success
            print("\nViewer > Fetched user model:\n\(model)")
            self?.userModel = model
            
            // update ui
            self?.displayNameLabel.text = self?.displayName
            self?.userIdLabel.text = self?.userModel?.id
            
            self?.fetchAvatarImage()
        }
        
    }
    
    /// Fetches the avatar image data and loads it into the avatar image view.
    fileprivate func fetchAvatarImage() {
        
        guard let url = self.userModel?.avatarURL else { return }
        
        guard let encodedURL = try? BLOCKv.encodeURL(url) else { return }
        
        // request image data
        manager.request(encodedURL).responseData { [weak self] responseData in
                        
            guard let data = responseData.data else { return }
            print("\nViewer > Avatar download successful.")
            
            self?.avatarImageView.alpha = 0.2
            UIView.animate(withDuration: 2, animations: {
                self?.avatarImageView.alpha = 1
            })
            
            self?.avatarImageView.image = UIImage(data: data)
            self?.view.setNeedsDisplay()
        }
        
    }
    
    /// Presents the image picker.
    @objc fileprivate func presentImagePicker() {
        present(picker, animated: true, completion: nil) //FIXME: iPad requires popover presentation
    }
    
    /// Uploads an avatar image to the BlockV platform.
    fileprivate func uploadImage(_ image: UIImage) {
        
        // show progress view
        uploadState = .busy
        
        // do avatar upload
        BLOCKv.uploadAvatar(image, progressCompletion: { [weak self] percent in
            
            self?.uploadProgressView.setProgress(percent, animated: true)
            print("Percent complete: \(percent)")
            
        }) { [weak self] error in
            
            // hide progress view
            self?.uploadState = .none
            
            // handle error
            guard error == nil else {
                print(">>> Error > Viewer: \(error!.localizedDescription)\n")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }
            
            // handle success
            print("\nViewer > Avatar upload successful.")
            
            // re-fetch the user's profile
            self?.fetchUserProfile()
            
        }
        
    }
    
    /// Logs the user out.
    fileprivate func logout() {
        
        BLOCKv.logout { [weak self] error in
            
            // Immediately pop the user to the onboarding view controller.
            
            // change root view controller
            self?.changeToOnboardingViewController()
            
            // dismiss
            self?.dismiss(animated: true, completion: nil)
            
            // Inspect the network response
            
            // handle error
            guard error == nil else {
                print(">>> Error > Viewer: \(error!.localizedDescription)\n")
                self?.present(UIAlertController.errorAlert(error!), animated: true)
                return
            }
            
            // handle success
            print("\nViewer > Logged Out.")
            
            
        }
        
    }
    
    /// Returns a description of the apps version and build.
    func versionString() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "Version \(version) (\(build))"
    }
    
    // MARK: - Navigation
    
    /// Prepares for navigation.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seg.profile.userInfo" {
            let vc = segue.destination as! UserInfoTableViewController
            vc.userModel = self.userModel
        } else if segue.identifier == "seg.profile.tokens" {
            let vc = segue.destination as! VerifyTableViewController
            vc.origin = .profile
        }
    }
    
    /// Changes view controller graph to show welcome screen.
    fileprivate func changeToOnboardingViewController() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "sid.main.nav") as! UINavigationController
        UIApplication.shared.keyWindow?.rootViewController = viewController
    }
    
}

// MARK: -  UITableViewDelegate, UITableViewDataSource

extension ProfileViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch TableSection(rawValue: indexPath.section)! {
        case .general:
            print(#function)
        case .logout:
            self.logout()
        }
    }

}

extension ProfileViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else  {
            print(">>> Error > Viewer: Failed to pick image.\n")
            return
        }
        
        self.uploadImage(pickedImage)
        picker.dismiss(animated: true, completion: nil)
        
    }
    
}
