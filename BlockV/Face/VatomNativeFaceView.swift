//
//  VatomFaceView.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/08/16.
//

import UIKit


/// does this need to be sepatate from vatom view? why?
class VatomNativeFaceView: UIView {

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.backgroundColor = .red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
