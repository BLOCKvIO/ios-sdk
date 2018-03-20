//
//  VatomStore.swift
//  BlockV_Example
//
//  Created by Cameron McOnie on 2018/03/12.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

/*
 Ideas:
 
 VatomStore - base class that manages a group of vatoms, actions, faces.
 
 VatomInventory - subclass of VatomStore that deals specifically with the current user's inventory.
 
 Web sockets
 
 - VatomInventory is the only vAtom Store subclass that needs to handle the Web socket. It must should generically handle the two modes (user full inventory ("parentID": ".") or a vatom's subvAtoms ("parentID": ".")
 
 Needs two constructors
 - init()
 - init(parentID: String) // folder contents
 
 */

import Foundation
import BlockV

//protocol VatomContainer: class {
//
//    func refresh()
//
//    func vatom() -> [Vatom]
//
//    func faces() -> [Face]
//
//    func actions() -> [Action]
//
//}
//
///// This is a simple class designed to hold a store of vAtoms.
/////
/////
//class VatomStore: VatomContainer {
//
////    func refresh() {
////        <#code#>
////    }
////
////    func vatom() -> [VatomModel] {
////        <#code#>
////    }
////
////    func faces() -> [Face] {
////        <#code#>
////    }
////
////    func actions() -> [Action] {
////        <#code#>
////    }
////
//
//    typealias VatomRetriever = (@escaping (GroupModel?, BVError?) -> Void) -> Void
//
//    var retriever: VatomRetriever
//
//    init(retriever: @escaping VatomRetriever) {
//        self.retriever = retriever
//    }
//
//    func fetch() {
//        retriever { (group, error) in
//            //
//        }
//    }
//
//}

