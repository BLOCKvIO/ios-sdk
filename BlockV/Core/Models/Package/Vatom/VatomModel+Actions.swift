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

extension VatomModel {

    /// `true` if the split action is registered, `false` otherwise.
    var hasSplitAction: Bool {
        self.hasAction("split")
    }

    /// `true` is the combine action is registered, `false` otherwise.
    var hasCombineAction: Bool {
        self.hasAction("combine")
    }

    /// Returns `true` if the packaged vatom contains an action of the specified name.
    public func hasAction(_ name: String) -> Bool {
        self.actionModels.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
    }
    
}
