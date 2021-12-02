//
//  VatomModel+Blockchain.swift
//  BLOCKv
//
//  Created by Josh Fox on 2021/12/02.
//

import Foundation

/// Helper utilities for dealing with vAtoms on the blockchain
extension VatomModel {
    
    /// True if the vatom is on an Ethereum blockchain
    public var isOnEthereum: Bool {
        return self.eth?.objectValue != nil
    }
    
    /// Ethereum network ID, or a blank string if not on Ethereum
    public var ethereumNetworkID: String {
        return self.eth?["network"]?.stringValue ?? ""
    }
    
    /// Ethereum network readable name
    public var ethereumNetworkName: String {
        let ethNetworkID = self.ethereumNetworkID
        if ethNetworkID == "" { return "--" }
        if ethNetworkID == "matic_mainnet" { return "Polygon" }
        if ethNetworkID == "matic_testnet" { return "Polygon (testnet)" }
        if ethNetworkID == "bsc_mainnet" { return "Binance" }
        if ethNetworkID == "bsc_testnet" { return "Binance (testnet)" }
        if ethNetworkID == "mainnet" { return "Ethereum" }
        if ethNetworkID == "testnet" { return "Ethereum (testnet)" }
        if ethNetworkID == "kaleido" { return "Kaleido" }
        if ethNetworkID == "palm" { return "Palm" }
        return ethNetworkID
    }
    
    /// Ethereum smart contract address
    public var ethereumContractAddress: String {
        
        // NOTE: This logic was copied from: https://github.com/VatomInc/web-viewer-open/blob/9d3dde8ba8c4461d82d0468ed7c6e0aad96af488/src/Common/Actions.ts#L81
        
        // Check for default address
        let addr = self.eth?["contract"]?.stringValue ?? ""
        if addr.isEmpty || addr == "bv-vatom-v1" {
            return "0x210e74c878d96c4aa1e9cbaf32fe1950dee2ca53"
        }
        
        // HACK: This is a hack because the contract is not appearing in the vatom eth section - only the Template
        let businessID = self.private?["studio-info-v1"]?["businessId"]?.stringValue ?? ""
        if businessID == "PoIvoqVCm3" {
            return "0x26D1319C38B3979CFA062146245Ccb3424Bb4B53"
        }
        
        // Use listed contract address
        return addr
        
    }
    
    /// True if minted on a blockchain
    public var isMinted: Bool {
        return self.eth?["emitted"]?.boolValue == true
    }
    
}
