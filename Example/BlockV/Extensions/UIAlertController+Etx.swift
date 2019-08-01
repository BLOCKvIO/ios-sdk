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
import BLOCKv

extension UIAlertController {
    
    /// Returns an alert view titled `title` with `message` and single "OK" action
    /// with no handler.
    ///
    /// This should not be used in production apps as-is. It is merely to surface
    /// the underlying platform error for this example app.
    static func errorAlert(_ error: BVError) -> UIAlertController {
        
        let alertController = UIAlertController.init(title: "Error",
                                                     message: error.localizedDescription,
                                                     preferredStyle: .alert)
        
        let dismissAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
        alertController.addAction(dismissAction)
        
        alertController.preferredAction = dismissAction
        
        return alertController
    }
    
    /// Returns an alert view titled `title` with `message` and single "OK" action with no handler.
    static func okAlert(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController.init(title: title,
                                                     message: message,
                                                     preferredStyle: .alert)
        
        let dismissAction = UIAlertAction.init(title: "OK", style: .default, handler: nil)
        alertController.addAction(dismissAction)
        
        alertController.preferredAction = dismissAction
        
        return alertController
    }
    
    /// Returns an alert view titled `title` with `message` and single "OK" action with no handler.
    static func infoAlert(message: String, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController.init(title: "Info",
                                                     message: message,
                                                     preferredStyle: .alert)
        
        let dismissAction = UIAlertAction.init(title: "OK", style: .default, handler: handler)
        alertController.addAction(dismissAction)
        
        alertController.preferredAction = dismissAction
        
        return alertController
    }
    
    static func confirmAlert(title: String,
                             message: String,
                             confirmed: @escaping (Bool) -> Void) -> UIAlertController {
        let alertController = UIAlertController.init(title: title,
                                                     message: message,
                                                     preferredStyle: .alert)
        
        let okAction = UIAlertAction.init(title: "OK", style: .default) { action in
            confirmed(true)
        }
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .destructive) { action in
            confirmed(false)
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        return alertController
    }
    
}
