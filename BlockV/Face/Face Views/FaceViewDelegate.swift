//
//  FaceViewDelegate.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/09/10.
//

import Foundation

/*
 Is there any way for the Viewer to inject the code into vatom view?
 In other words, there must be some way for vatom view to handle all the variety of interfaces to the native faces.
 Each face view will want specific methods in the SDK (which they can call directly), and functionality they need the
 viewer to provide - this is harder to do in a type safe way...
 */

/// An interface type that manage a vAtom view must conform to.
///
/// VatomView will mediate method calls from the face view. Face View's each have their own interface which VatomView
/// must conform to. VatomView often needs to delegate the methods on to the type managing it.
//protocol VatomViewDelegate: class {
//    
//    /// Close the VatomView. The face view is requesting it be removed from focus.
//    func close()
//    
//}
//
//class VatomView_test {
//    
//    weak var delegate: VatomViewDelegate?
//    
//}
//
//
//
//
//protocol ImageRedeemableFaceDelegate {
//
//    /// Face view is requesting itself be closed.
//    func closeFaceView()
//    
//    /// Face view is requeesting the viewer bring up a merchant confirmation screen and call a closure with the outcome.
//    func showMerchantConfirmationScreen(completion: () -> Error?)
//
//}

/// Goal:
///
/// VatomView is made to adopt face view protocols by extensions. This allows embedded and viewer-side faces to
/// extend VatomView and 'inject' the functionalty they requrie.
//extension VatomView_test: ImageRedeemableFaceDelegate {
//
//    func closeFaceView() {
//        self.delegate.close()
//    }
//
//}
