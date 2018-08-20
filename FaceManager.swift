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
