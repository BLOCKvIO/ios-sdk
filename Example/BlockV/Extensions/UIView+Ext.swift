//
//  UIView+Ext.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/17.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

extension UIView {
    
    /// Animates the view's alpha to zero.
    func alphaOut() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
        }
    }
    
    /// Animates the view's alpha to one.
    func alphaIn() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
}
