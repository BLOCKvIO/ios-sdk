//
//  BVConfiguration.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/06/26.
//

import Foundation

class BVConfiguration {

    var appID: String?

    /// Models the BLOCKv platform environments.
    ///
    /// Options:
    /// - production.
    /// - developement (Unstable - DO NOT USE).
    public enum BVEnvironment {
        /// Stable production environment.
        case production
        /// Unstable development environement (DO NOT USE).
        case development

        /// BLOCKv server base url
        var apiServerURLString: String {
            switch self {
            case .production:  return "https://api.blockv.io"
            case .development: return "https://apidev.blockv.net"
            }
        }

        /// BLOCKv Web socket server base url
        var webSocketURLString: String {
            switch self {
            case .production:  return "wss//newws.blockv.io/ws"
            case .development: return "wss://ws.blockv.net/ws"
            }
        }

    }

}
