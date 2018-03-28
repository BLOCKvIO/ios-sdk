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

//
//  Adapted from robertmryan: https://github.com/robertmryan
//

import Foundation
import Alamofire

class NetworkOperation: AsynchronousOperation {
    
    // define properties to hold everything that you'll supply when you instantiate
    // this object and will be used when the request finally starts
    //
    // in this example, I'll keep track of (a) URL; and (b) closure to call when request is done
    
    private let urlString: String
    private var networkOperationCompletionHandler: ((_ responseObject: Any?, _ error: Error?) -> Void)?
    
    // we'll also keep track of the resulting request operation in case we need to cancel it later
    
    weak var request: Alamofire.Request?
    
    // define init method that captures all of the properties to be used when issuing the request
    
    init(urlString: String, networkOperationCompletionHandler: ((_ responseObject: Any?, _ error: Error?) -> Void)? = nil) {
        self.urlString = urlString
        self.networkOperationCompletionHandler = networkOperationCompletionHandler
        super.init()
    }
    
    // when the operation actually starts, this is the method that will be called
    
    override func main() {
        request = Alamofire.request(urlString, method: .get)
            .responseJSON { response in
                // do whatever you want here; personally, I'll just all the completion handler that was passed to me in `init`
                
                self.networkOperationCompletionHandler?(response.result.value, response.result.error)
                self.networkOperationCompletionHandler = nil
                
                // now that I'm done, complete this operation
                
                self.completeOperation()
        }
    }
    
    // we'll also support canceling the request, in case we need it
    
    override func cancel() {
        request?.cancel()
        super.cancel()
    }
}
