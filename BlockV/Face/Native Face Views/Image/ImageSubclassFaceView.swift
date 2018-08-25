//
//  ImageSubclassFaceView.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/08/25.
//

import Foundation

/// Just to test that subclassing works as expected.
class ImageSubclassFaceView: ImageFaceView {

    override class var displayURL: String {
        return "native://some-subclass"
    }

    required init(vatomPack: VatomPackModel, selectedFace: FaceModel) {
        super.init(vatomPack: vatomPack, selectedFace: selectedFace)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
