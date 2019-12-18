//
//  BLOCKv AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BLOCKv SDK License (the "License"); you may not use this file or
//  the BLOCKv SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BLOCKv SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import Foundation

/// Possible events
public enum RegionEvent: String {

    /// Triggered when any data in the region changes. This also indicates that there is no longer an error.
    case updated = "region.updated"

    // will change

    /// Triggered when an object is added.
    case willAddObject = "region.object.will_add"

    /// Triggered when an object will be removed.
    case willRemoveObject = "region.object.will_remove"

    /// When a data object changes. userInfo["id"] is the ID of the changed object.
    case willUpdateObject = "region.object.will_update"

    // did change

    /// Triggered after an object was added.
    case didAddObject = "region.object.did_add"

    /// Triggered after an object was removed.
    case didRemoveObject = "region.object.did_remove"

    /// Triggered after an object was updated.
    case didUpdateObject = "region.object.did_update"

    /// When an error occurs. userInfo["error"] is the error. You can also access `region.error` to get the error.
    case error = "region.error"

    /// Lifecycle events

    /// Triggered when the region stabalizes.
    case stabalized = "region.stabalized"
    /// Triggered when the region destabalizes.
    case destabalized = "region.destablaized"
    /// Triggered when the region begins synchronization.
    case synchronizing = "region.synchronizing"

}

extension RegionEvent {

    /// Convert the notification to a Notification.Name
    public var asNotification: Notification.Name {
        return Notification.Name(rawValue: self.rawValue)
    }

}

/// Helpers to deal with events
extension Region {

    /// Add a listener.
    public func addObserver(_ observer: Any, selector: Selector, name: RegionEvent) {
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: Notification.Name(name.rawValue),
                                               object: self)
    }

    /// Remove a listener.
    public func removeObserver(_ observer: Any, name: RegionEvent) {
        NotificationCenter.default.removeObserver(observer,
                                                  name: Notification.Name(name.rawValue),
                                                  object: self)
    }

    /// Removes a set listener.
    /// TODO: Find a way to auto remove block listeners when their container object is dealloc'd?
    public typealias RemoveObserverFunction = () -> Void

    /// Add a listener
    public func listen(for name: RegionEvent, handler: @escaping (Notification) -> Void) -> RemoveObserverFunction {

        // register observer
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name(name.rawValue),
                                                              object: self, queue: OperationQueue.main, using: handler)

        // return a function which can be called to remove the observer
        return {
            NotificationCenter.default.removeObserver(observer)
        }

    }

    /// Emits an event. This is used by Region and it's subclasses only.
    func emit(_ name: RegionEvent, userInfo: [String: Any] = [:]) {

        // send notification
        NotificationCenter.default.post(name: Notification.Name(name.rawValue), object: self, userInfo: userInfo)

    }

}
