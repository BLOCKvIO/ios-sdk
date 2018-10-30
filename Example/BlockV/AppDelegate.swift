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
//  AppDelegate.swift
//  BlockV_Example
//

import UIKit
import BLOCKv
import VatomFace3D

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    internal var webSocketManager: WebSocketManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //: ## Setup
                
        BLOCKv.configure(appID: MyAppID)
        FaceViewRoster.shared.register(Face3D.self)
        
        //: ## Control Flow

        print("\nViewer > isLoggedIn - \(BLOCKv.isLoggedIn)")
        
        func showWelcome() {
            // show 'welcome' view controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nc = storyboard.instantiateInitialViewController() as! UINavigationController
            let rootVC = storyboard.instantiateViewController(withIdentifier: "sid.welcome.vc")
            nc.viewControllers = [rootVC]
            self.window?.rootViewController = nc
        }
        
        func showInventory() {
            // show 'inventory' view controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nc = storyboard.instantiateViewController(withIdentifier: "sid.inventory.nc") as! UINavigationController
            let rootVC = storyboard.instantiateViewController(withIdentifier: "sid.inventory.vc") as! InventoryCollectionViewController
            nc.viewControllers = [rootVC]
            self.window?.rootViewController = nc
        }
        
        // Set window's vc based on the login state
        if BLOCKv.isLoggedIn {
            showInventory()
        } else {
            showWelcome()
        }
        
        //: ## Handle logout
        
        // This closure will be called when the BLOCKv SDK requires re-authorization.
        BLOCKv.onLogout = {
            // store a closure in the `onLogout` variable.
            showWelcome()
        }
        
        // Theme
        window?.tintColor = UIColor.seafoamBlue
        
        return true
    }

}
