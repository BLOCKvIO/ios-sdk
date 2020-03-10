//
//  BlockV AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BlockV SDK License (the "License"); you may not use this file or
//  the BlockV SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BlockV SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import UIKit


protocol ObserverTokenStore : class {
    func addObserverToken(_ token: NSObjectProtocol)
}


/// This is a helper protocol for the SyncCoordinator.
///
/// It receives application active / background state changes and forwards them after switching onto the right queue.
protocol ApplicationActiveStateObserving : class, ObserverTokenStore {
    /// Runs the given block on the right queue and dispatch group.
    func perform(_ block: @escaping () -> ())
    
    /// Called when the application becomes active (or at launch if it's already active).
    func applicationDidBecomeActive()
    func applicationDidEnterBackground()
}


extension ApplicationActiveStateObserving {
    func setupApplicationActiveNotifications() {
        addObserverToken(NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                object: nil, queue: nil) { [weak self] note in
            guard let observer = self else { return }
            observer.perform {
                observer.applicationDidEnterBackground()
            }
        })
        addObserverToken(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                                object: nil, queue: nil) { [weak self] note in
            guard let observer = self else { return }
            observer.perform {
                observer.applicationDidBecomeActive()
            }
        })
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                self.applicationDidBecomeActive()
            }
        }
    }
}
