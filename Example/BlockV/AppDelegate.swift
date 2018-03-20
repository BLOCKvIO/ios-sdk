//
//  AppDelegate.swift
//  BlockV
//
//  Created by cjmconie on 01/10/2018.
//  Copyright (c) 2018 cjmconie. All rights reserved.
//

import UIKit
import BlockV

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Theme
        window?.tintColor = UIColor.seafoamBlue
        
        // Set appID
        Blockv.configure(appID: MyApiKey)
        
        // Set platform environment
        Blockv.setEnvironment(.development)
        
        print("\nViewer > isLoggedIn: \(Blockv.isLoggedIn)")
        
        // Set window's vc based on the login state
        if Blockv.isLoggedIn {
            // show 'inventory' view controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nc = storyboard.instantiateViewController(withIdentifier: "sid.inventory.nc") as! UINavigationController
            let rootVC = storyboard.instantiateViewController(withIdentifier: "sid.inventory.vc") as! InventoryCollectionViewController
            nc.viewControllers = [rootVC]
            self.window?.rootViewController = nc
        } else {
            // show 'welcome' view controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nc = storyboard.instantiateInitialViewController() as! UINavigationController
            let rootVC = storyboard.instantiateViewController(withIdentifier: "sid.welcome.vc")
            nc.viewControllers = [rootVC]
            self.window?.rootViewController = nc
        }
        
        return true
    }

}
