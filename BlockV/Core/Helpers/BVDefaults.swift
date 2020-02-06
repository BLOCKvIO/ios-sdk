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

class BVDefaults {
    
    // singleton
    static let shared = BVDefaults()
    
    let defaults = UserDefaults.standard
    
    enum Key: String, CaseIterable {
        case inventoryLastHash = "io.blockv.defaults.inventory-last-hash"
        case inventoryLastFaceActionFetch = "io.blockv.defaults.inventory-last-face-action-fetch"
    }
    
    /// Storage of the inventory region hash value.
    var inventoryLastHash: String? {
        get { defaults.string(forKey: Key.inventoryLastHash.rawValue) }
        set { defaults.set(newValue, forKey: Key.inventoryLastHash.rawValue) }
    }
    
    /// Storage of time stamp of last face action fetch (measured as time inteval since 1970).
    var inventoryLastFaceActionFetch: TimeInterval? {
        get { defaults.double(forKey: Key.inventoryLastFaceActionFetch.rawValue) }
        set { defaults.set(newValue, forKey: Key.inventoryLastFaceActionFetch.rawValue) }
    }
    
    /// Resets the defaults to their default state.
    func clear() {
        for key in Key.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
    }
    
}
