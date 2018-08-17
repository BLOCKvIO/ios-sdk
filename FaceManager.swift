//
//  FaceManager.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2018/08/16.
//

import Foundation

public struct FaceManager {
    
    // MARK: - Type Alias
    
    ///
    public typealias NativeViewGenerator = (_ vatom: VatomModel, _ face: FaceModel) -> UIView
    
    // MARK: - Properties
    
    /// Dictionary of native faces.
    ///
    /// Viewer should
    private var nativeFaces: [String : NativeViewGenerator] = [:]
    
    // MARK: - Methods
    
    /// Registers a native view generator.
    ///
    /// - Parameters:
    ///   - generator: A closure that take in a vatom and a face and generates a UIView.
    ///   - url: The display url
    public func register(generator: NativeViewGenerator, forDisplayURL url: String) {
        
        // register the native face somewhere
        
    }
    
}
