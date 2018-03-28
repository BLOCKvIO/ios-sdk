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

import UIKit
import BlockV

class TokenCell: UITableViewCell {
    
    // MARK: - Enums
    
    /// Boolean indicating whether the token is verified.
    /// `true` if verified. `false` otherwise.
    fileprivate var isVerified: Bool = false {
        willSet {
            resendCodeButton.isHidden = newValue
            verifiyCodeTextField.isHidden = newValue
            verifyCodeButton.isHidden = newValue
        }
    }
    
    fileprivate var userToken: UserToken? {
        willSet {
            guard let token = newValue else { return }
            self.tokenTypeLabel.text = "Type: \(token.type.rawValue)"
            self.tokenTextField.text = token.value
        }
    }
    
    // MARK: - Properties
    
    // This delegate is responsible for 
    weak var delegate: VerfiyTokenDelegate?
    
    // MARK: - Outlets
    
    @IBOutlet weak var tokenTypeLabel: UILabel!
    @IBOutlet weak var tokenTextField: UITextField!
    @IBOutlet weak var verifiyCodeTextField: UITextField!
    @IBOutlet weak var resendCodeButton: UIButton!
    @IBOutlet weak var verifyCodeButton: UIButton!
    
    // MARK: - Helpers
    
    /// Configure with a user token (isVerified is set to `false`).
    func configure(userToken: UserToken) {
        self.userToken = userToken
        self.isVerified = false
    }
    
    /// Configre with a full token.
    func configure(fullToken: FullTokenModel) {
        
        // convert to a user token (if possible)
        if fullToken.properties.tokenType == "phone_number" {
            self.userToken = UserToken(value: fullToken.properties.token, type: .phone)
            self.isVerified = fullToken.properties.isConfirmed
            return
        } else if fullToken.properties.tokenType == "email" {
            self.userToken = UserToken(value: fullToken.properties.token, type: .email)
            self.isVerified = fullToken.properties.isConfirmed
            return
        }
        
        // otherwise it's a OAuth or other
        self.tokenTypeLabel.text = fullToken.properties.tokenType
        self.tokenTextField.text = fullToken.properties.token
        self.isVerified = true // set to `true` to prevent verification ui
    }
    
    // MARK: - Actions
    
    @IBAction func resendButtonTapped(_ sender: UIButton) {
        
        // only allow resend if it is a user token
        guard let token = self.userToken else { return }
        
        self.delegate?.resendVerification(token: token) { success in
            // update ui
        }
        
    }
    
    @IBAction func verifyButtonTapped(_ sender: UIButton) {
        
        // only allow verify if it is a user token
        guard let token = self.userToken else { return }
        
        let code = verifiyCodeTextField.text ?? ""
        self.delegate?.verifyUserToken(token: token, code: code) { success in
            // update ui
        }
        
    }
    
}
