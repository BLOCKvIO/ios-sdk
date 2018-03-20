//
//  VatomCell.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import BlockV

class VatomCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static let reuseIdentifier = "com.blockv.vatom-cell"
    
    var vatom: Vatom?
    
    // MARK: - Outlets
    
    @IBOutlet weak var activatedImageView: UIImageView!
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // reset
        self.activatedImageView.image = nil
        
    }
    
}
