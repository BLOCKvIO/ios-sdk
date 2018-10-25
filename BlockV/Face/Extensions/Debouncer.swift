//  MIT License
//
//  Copyright (c) Simon Ljungberg
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

extension TimeInterval {

    /**
     Checks if `since` has passed since `self`.
     
     - Parameter since: The duration of time that needs to have passed for this function to return `true`.
     - Returns: `true` if `since` has passed since now.
     */
    func hasPassed(since: TimeInterval) -> Bool {
        return Date().timeIntervalSinceReferenceDate - self > since
    }

}

/**
 Wraps a function in a new function that will only execute the wrapped function if `delay` has passed without this
 function being called.
 
 - Parameter delay: A `DispatchTimeInterval` to wait before executing the wrapped function after last invocation.
 - Parameter queue: The queue to perform the action on. Defaults to the main queue.
 - Parameter action: A function to debounce. Can't accept any arguments.
 
 - Returns: A new function that will only call `action` if `delay` time passes between invocations.
 */
func debounce(delay: DispatchTimeInterval,
              queue: DispatchQueue = .main,
              action: @escaping (() -> Void)) -> () -> Void {
    var currentWorkItem: DispatchWorkItem?
    return {
        currentWorkItem?.cancel()
        currentWorkItem = DispatchWorkItem { action() }
        queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

/**
 Wraps a function in a new function that will only execute the wrapped function if `delay` has passed without this
 function being called.
 
 Accepsts an `action` with one argument.
 - Parameter delay: A `DispatchTimeInterval` to wait before executing the wrapped function after last invocation.
 - Parameter queue: The queue to perform the action on. Defaults to the main queue.
 - Parameter action: A function to debounce. Can accept one argument.
 - Returns: A new function that will only call `action` if `delay` time passes between invocations.
 */
func debounce<T>(delay: DispatchTimeInterval,
                 queue: DispatchQueue = .main,
                 action: @escaping ((T) -> Void)) -> (T) -> Void {
    var currentWorkItem: DispatchWorkItem?
    return { (param1: T) in
        currentWorkItem?.cancel()
        currentWorkItem = DispatchWorkItem { action(param1) }
        queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

/**
 Wraps a function in a new function that will only execute the wrapped function if `delay` has passed without this
 function being called.
 Accepsts an `action` with two arguments.
 - Parameter delay: A `DispatchTimeInterval` to wait before executing the wrapped function after last invocation.
 - Parameter queue: The queue to perform the action on. Defaults to the main queue.
 - Parameter action: A function to debounce. Can accept two arguments.
 - Returns: A new function that will only call `action` if `delay` time passes between invocations.
 */
func debounce<T, U>(delay: DispatchTimeInterval,
                    queue: DispatchQueue = .main,
                    action: @escaping ((T, U) -> Void)) -> (T, U) -> Void {
    var currentWorkItem: DispatchWorkItem?
    return { (param1: T, param2: U) in
        currentWorkItem?.cancel()
        currentWorkItem = DispatchWorkItem { action(param1, param2) }
        queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}
