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

// MARK: - Face Changes

public struct FaceChangesModel: Codable {
    
    public let faceChanges: [String: [FaceInnerModel]]
    
    enum CodingKeys: String, CodingKey {
        case faceChanges = "faces_changes"
    }
}

public struct FaceInnerModel: Codable {
    public let face: FaceModel
    public let opertation: String
}

// MARK: - Action Models

public struct ActionChangesModel: Codable {
    
    public let actionChanges: [String: [ActionInnerModel]]
    
    enum CodingKeys: String, CodingKey {
        case actionChanges = "actions_changes"
    }
}


public struct ActionInnerModel: Codable {
    public let action: ActionModel
    public let operation: String
}
