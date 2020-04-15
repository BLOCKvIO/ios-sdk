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

/// This extension groups together all BLOCKv vatom requests.
extension BLOCKv {
    
    /// Fetches the current user's inventory hash.
    ///
    /// - Parameter completion: Completion hanlder that so called once the request completes.
    public static func getInventoryHash(completion: @escaping (Result<InventoryHashModel, BVError>) -> Void) {
        
        let endpoint = API.Vatom.getInventoryHash()

        self.client.request(endpoint) { result in
            switch result {
            case .success(let model):
                // model is available
                DispatchQueue.main.async {
                    completion(.success(model.payload))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
    }
    
    /// Fetches the current user’s inventory vatoms’ sync numbers.
    ///
    /// - Parameters:
    ///   - limit: Paging limit.
    ///   - token: Paging token.
    ///   - completion: Completion hanlder that so called once the request completes.
    public static func getInventoryVatomSyncNumbers(limit: Int, token: String, completion: @escaping (Result<InventorySyncModel, BVError>) -> Void) {
        
        let endpoint = API.Vatom.getInventoryVatomSyncNumbers(limit: limit, token: token)
        
        self.client.request(endpoint) { result in
            switch result {
            case .success(let model):
                // model is available
                DispatchQueue.main.async {
                    completion(.success(model.payload))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
    }
    
    /// Fetches the face changes for the specified template ids after the specified time.
    ///
    /// - Parameters:
    ///   - templateIds: List of local template ids whose changes should be fetched.
    ///   - since: Unix epoch after which changes should be fetched (measured in milliseconds).
    ///   - completion: Completion hanlder that so called once the request completes.
    public static func getFaceChanges(templateIds: [String], since: Double, completion: @escaping (Result<FaceChangesModel, BVError>) -> Void) {
        
        let endpoint = API.Vatom.getFaceChanges(templateIds: templateIds, since: since)
        
        self.client.request(endpoint) { result in
            switch result {
            case .success(let model):
                // model is available
                DispatchQueue.main.async {
                    completion(.success(model.payload))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
    }
    
    /// Fetches the action changes for the specified template ids after the specified time.
    ///
    /// - Parameters:
    ///   - templateIds: List of local template ids whose changes should be fetched.
    ///   - since: Unix epoch after which changes should be fetched (measured in milliseconds).
    ///   - completion: Completion hanlder that so called once the request completes.
    public static func getActionChanges(templateIds: [String], since: Double, completion: @escaping (Result<ActionChangesModel, BVError>) -> Void) {
        
        let endpoint = API.Vatom.getActionChanges(templateIds: templateIds, since: since)
        
        self.client.request(endpoint) { result in
            switch result {
            case .success(let model):
                // model is available
                DispatchQueue.main.async {
                    completion(.success(model.payload))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
    }
    
}
