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

// For reference: https://stackoverflow.com/a/45221496
extension Dictionary {

    /// Merges one dictionary with another.
    public func deepMerged(with other: [Key: Value]) -> [Key: Value] {
        var result: [Key: Value] = self
        for (key, value) in other {
            if let value = value as? [Key: Value],
                let existing = result[key] as? [Key: Value],
                let merged = existing.deepMerged(with: value) as? Value {
                result[key] = merged
            } else {
                result[key] = value
            }
        }
        return result
    }
}
