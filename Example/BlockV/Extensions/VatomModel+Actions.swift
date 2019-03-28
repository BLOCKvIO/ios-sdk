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

import Foundation
import BLOCKv

/// Action Extensions
extension VatomModel {
    
    /// Clones this vAtom to the specified token.
    ///
    /// Note: Calling this action will trigger the action associated with this vAtom's
    /// template. If an action has not been configured, an error will be generated.
    ///
    /// - Parameters:
    ///   - token: Standard UserToken (Phone, Email, or User ID)
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func clone(toToken token: UserToken,
                      completion: @escaping ([String: Any]?, BVError?) -> Void) {
        
        let body = [
            "this.id": self.id,
            "new.owner.\(token.type.rawValue)": token.value
        ]
        
        // perform the action
        BLOCKv.performAction(name: "Clone", payload: body) { (json, error) in
            //TODO: should it be weak self?
            completion(json, error)
        }
        
    }
    
    /// Redeems this vAtom to the specified token.
    ///
    /// Note: Calling this action will trigger the action associated with this vAtom's
    /// template. If an action has not been configured, an error will be generated.
    ///
    /// - Parameters:
    ///   - token: Standard UserToken (Phone, Email, or User ID)
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    public func redeem(toToken token: UserToken,
                       completion: @escaping ([String: Any]?, BVError?) -> Void) {
        
        let body = [
            "this.id": self.id,
            "new.owner.\(token.type.rawValue)": token.value
        ]
        
        // perform the action
        BLOCKv.performAction(name: "Redeem", payload: body) { (json, error) in
            //TODO: should it be weak self?
            completion(json, error)
        }
        
    }
    
}
