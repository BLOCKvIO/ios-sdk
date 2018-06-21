//
//  Notification+Ext.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/06/21.
//

import Foundation

// MARK: - BLOCKv

extension Notification.Name {
    
    // MARK: - Internal
    
    internal struct BVInternal {
        
        /// INTERNAL: Broadcast to indicate user authorization is required.
        internal static let UserAuthorizationRequried = Notification.Name("com.blockv.internal.user.auth.required")
        
    }

}
