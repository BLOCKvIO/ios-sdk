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
//  Adapted from Robert Ryan (https://github.com/robertmryan)
//

import Foundation

/// Asynchronous Operation base class
///
/// This class performs all of the necessary KVN of `isFinished` and
/// `isExecuting` for a concurrent `NSOperation` subclass. So, to developer
/// a concurrent NSOperation subclass, you instead subclass this class which:
///
/// - must override `main()` with the tasks that initiate the asynchronous task;
///
/// - must call `completeOperation()` function when the asynchronous task is done;
///
/// - optionally, periodically check `self.cancelled` status, performing any clean-up
///   necessary and then ensuring that `completeOperation()` is called; or
///   override `cancel` method, calling `super.cancel()` and then cleaning-up
///   and ensuring `completeOperation()` is called.
public class AsynchronousOperation : Operation {
    
    override public var isAsynchronous: Bool { return true }
    
    private let stateLock = NSLock()
    
    private var _executing: Bool = false
    override private(set) public var isExecuting: Bool {
        get {
            return stateLock.withCriticalScope { _executing }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            stateLock.withCriticalScope { _executing = newValue }
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    private var _finished: Bool = false
    override private(set) public var isFinished: Bool {
        get {
            return stateLock.withCriticalScope { _finished }
        }
        set {
            willChangeValue(forKey: "isFinished")
            stateLock.withCriticalScope { _finished = newValue }
            didChangeValue(forKey: "isFinished")
        }
    }
    
    /// Complete the operation
    ///
    /// This will result in the appropriate KVN of isFinished and isExecuting
    
    public func completeOperation() {
        if isExecuting {
            isExecuting = false
        }
        
        if !isFinished {
            isFinished = true
        }
    }
    
    override public func start() {
        if isCancelled {
            isFinished = true
            return
        }
        
        isExecuting = true
        
        main()
    }
    
    override public func main() {
        fatalError("subclasses must override `main`")
    }
}

extension NSLock {
    
    /// Perform closure within lock.
    ///
    /// An extension to `NSLock` to simplify executing critical code.
    ///
    /// - parameter block: The closure to be performed.
    
    func withCriticalScope<T>( block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

