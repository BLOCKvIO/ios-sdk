//
//  UIViewController+Ext.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/12.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /// Shows activity indicator on the right.
    func showNavBarActivityRight() {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.startAnimating()
        let item = UIBarButtonItem(customView: indicator)
        
        self.navigationItem.rightBarButtonItem = item
    }
    
    /// Hides activity indicator on the right.
    func hideNavBarActivityRight() {
        self.navigationItem.rightBarButtonItem = nil
    }
    
    /// Shows activty indicator on the left.
    func showNavBarActivityLeft() {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.startAnimating()
        let item = UIBarButtonItem(customView: indicator)
        
        self.navigationItem.leftBarButtonItem = item
    }
    
    /// Hides activity indicator on the left.
    func hideNavBarActivityLeft() {
        self.navigationItem.leftBarButtonItem = nil
    }
    
}
