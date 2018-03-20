//
//  UIAlertController+Etx.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/08.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import BlockV

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
    
}
