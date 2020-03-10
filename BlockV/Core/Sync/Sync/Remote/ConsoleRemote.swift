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

class ConsoleRemote: RemoteInterface {
    
    fileprivate func log(_ str: String) {
        print("--- Dummy network adapter logging to console ---\n* ", str)
    }
    
    func getInventoryHash(completion: @escaping (Result<String, BVError>) -> Void) {
        log(#function)
    }
    
    func getInventoryVatomSyncNumbers(limit: Int, token: String, queue: DispatchQueue = .main, completion: @escaping (Result<InventorySyncModel, BVError>) -> Void) {
        log(#function)
    }
    
    func getInventory(id: String, page: Int, limit: Int, queue: DispatchQueue, completion: @escaping (Result<UnpackedModel, BVError>) -> Void) {
        log(#function)
    }
    
    func getVatoms(withIDs ids: [String],  queue: DispatchQueue, completion: @escaping (Result<UnpackedModel, BVError>) -> Void) {
        log(#function)
    }
    
    func getVatom(withID id: String, queue: DispatchQueue, completion: @escaping (Result<VatomModel, BVError>) -> Void) {
        log(#function)
    }
    
    func getFaceChanges(templateIds: [String], since: Double, completion: @escaping (BaseModel<ActionChangesModel>) -> Void) {
        log(#function)
    }
    
    func getActionChanges(templateIds: [String], since: Double, completion: @escaping (BaseModel<FaceChangesModel>) -> Void) {
        log(#function)
    }
    
    func trashVatom(_ id: String, completion: @escaping (BVError?) -> Void) {
        log(#function)
    }
    
    func setParentID(ofVatoms vatoms: [VatomModel], to parentID: String, completion: @escaping (Result<VatomUpdateModel, BVError>) -> Void) {
        log(#function)
    }
    
    func performAction(name: String, payload: [String : Any], completion: @escaping (Result<[String : Any], BVError>) -> Void) {
        log(#function)
    }
    
    func acquireVatom(withID id: String, completion: @escaping (Result<[String : Any], BVError>) -> Void) {
        log(#function)
    }
    
    func acquirePubVariation(withID id: String, completion: @escaping (Result<[String : Any], BVError>) -> Void) {
        log(#function)
    }
    
}
