//  MIT License
//
//  Copyright (c) 2018 BlockV AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
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
import BLOCKv

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

