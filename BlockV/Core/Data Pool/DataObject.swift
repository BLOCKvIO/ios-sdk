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

/// Represents a raw data object, potentially without any data, which is monitored by a region.
class DataObject {

    /// Type unique identifier.
    var type: String = ""

    /// Identifier.
    var id: String = ""

    /// Freeform object.
    var data: [String: Any]?

    /// Cached concrete type.
    ///
    /// Plugins use the `map` function to transform raw `data` into a concrete type.
    /// This property is used to cache the transformed type. This avoids the overhead of performing the transformation.
    var cached: Any?
    
    init() { }
    
    init(id: String, type: String, data: [String: Any]? = nil, cached: Any? = nil) {
        self.id = id
        self.type = type
        self.data = data
        self.cached = cached
    }

}
