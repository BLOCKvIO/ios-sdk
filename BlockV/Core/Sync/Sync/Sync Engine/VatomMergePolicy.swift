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

import CoreData

public class VatomMergePolicy: NSMergePolicy {
    
    public enum MergeMode {
        case remote
        case local
        
        fileprivate var mergeType: NSMergePolicyType {
            switch self {
            case .remote: return .mergeByPropertyObjectTrumpMergePolicyType
            case .local: return .mergeByPropertyStoreTrumpMergePolicyType
            }
        }
    }
    
    required public init(mode: MergeMode) {
        super.init(merge: mode.mergeType)
    }
    
    //TODO: Add logic to deal with derrived attributes
}
