//
//  RoundedImageView.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/09.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class RoundedImageView: UIImageView {
    
    override func layoutSubviews() {
        self.layer.cornerRadius = self.frame.size.height / 2
        self.clipsToBounds = true
    }
    
}
