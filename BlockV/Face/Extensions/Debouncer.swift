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

/*
 - https://stackoverflow.com/questions/25991367/difference-between-throttling-and-debouncing-a-function
 - http://demo.nimius.net/debounce_throttle/
 */

extension TimeInterval {
    
    /**
     Checks if the current time has passed the reference date `since` plus some delay `self`.
     
     ```
     let lastRunDate = Date().timeIntervalSinceReferenceDate()
     let delay: TimeInterval = 3
     
     if delay.hasPassed(since: lastRunDate) {
     // at least 3 seconds has passed
     }
     
     ```
     
     - Parameter since: The reference date from which
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

/**
 Wraps a function in a new function that will throttle the execution to once in every `delay` seconds.
 
 - Parameter delay: A `TimeInterval` specifying the number of seconds that needst to pass between each execution of `action`.
 - Parameter queue: The queue to perform the action on. Defaults to the main queue.
 - Parameter action: A function to throttle.
 
 - Returns: A new function that will only call `action` once every `delay` seconds, regardless of how often it is called.
 */
func throttle(delay: TimeInterval, queue: DispatchQueue = .main, action: @escaping (() -> Void)) -> () -> Void {
    var currentWorkItem: DispatchWorkItem?
    var lastFire: TimeInterval = 0
    return {
        guard currentWorkItem == nil else { return }
        currentWorkItem = DispatchWorkItem {
            action()
            lastFire = Date().timeIntervalSinceReferenceDate
            currentWorkItem = nil
        }
        delay.hasPassed(since: lastFire) ? queue.async(execute: currentWorkItem!) : queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

/**
 Wraps a function in a new function that will throttle the execution to once in every `delay` seconds.
 
 Accepts an `action` with one argument.
 - Parameter delay: A `TimeInterval` specifying the number of seconds that needst to pass between each execution of `action`.
 - Parameter queue: The queue to perform the action on. Defaults to the main queue.
 - Parameter action: A function to throttle. Can accept one argument.
 - Returns: A new function that will only call `action` once every `delay` seconds, regardless of how often it is called.
 */
func throttle1<T>(delay: TimeInterval, queue: DispatchQueue = .main, action: @escaping ((T) -> Void)) -> (T) -> Void {
    var currentWorkItem: DispatchWorkItem?
    var lastFire: TimeInterval = 0
    return { (p1: T) in
        guard currentWorkItem == nil else { return }
        currentWorkItem = DispatchWorkItem {
            action(p1)
            lastFire = Date().timeIntervalSinceReferenceDate
            currentWorkItem = nil
        }
        delay.hasPassed(since: lastFire) ? queue.async(execute: currentWorkItem!) : queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

/**
 Wraps a function in a new function that will throttle the execution to once in every `delay` seconds.
 Accepts an `action` with two arguments.
 - Parameter delay: A `TimeInterval` specifying the number of seconds that needst to pass between each execution of `action`.
 - Parameter queue: The queue to perform the action on. Defaults to the main queue.
 - Parameter action: A function to throttle. Can accept two arguments.
 - Returns: A new function that will only call `action` once every `delay` seconds, regardless of how often it is called.
 */

func throttle2<T, U>(delay: TimeInterval, queue: DispatchQueue = .main, action: @escaping ((T, U) -> Void)) -> (T, U) -> Void {
    var currentWorkItem: DispatchWorkItem?
    var lastFire: TimeInterval = 0
    return { (p1: T, p2: U) in
        guard currentWorkItem == nil else { return }
        currentWorkItem = DispatchWorkItem {
            action(p1, p2)
            lastFire = Date().timeIntervalSinceReferenceDate
            currentWorkItem = nil
        }
        delay.hasPassed(since: lastFire) ? queue.async(execute: currentWorkItem!) : queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}
