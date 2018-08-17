//
//  VatomWebFaceView.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/08/16.
//

import UIKit
import WebKit

class VatomWebFaceView: UIView {

    var webView: WKWebView?
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.backgroundColor = .blue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
