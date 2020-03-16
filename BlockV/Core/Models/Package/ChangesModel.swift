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

// MARK: - Action Changes

struct ActionChangesModel: Codable {
    
    let faceChanges: [String: [FaceInnerModel]]
    
    enum CodingKeys: String, CodingKey {
        case faceChanges = "faces_changes"
    }
}

struct ActionInnerModel: Codable {
    let action: ActionModel
    let operation: String
}

// MARK: - Face Models

struct FaceChangesModel: Codable {
    
    let actionChanges: [String: [ActionInnerModel]]
    
    enum CodingKeys: String, CodingKey {
        case actionChanges = "actions_changes"
    }
}

struct FaceInnerModel: Codable {
    let face: FaceModel
    let opertation: String
}


