//
//  BLOCKvRemote.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2019/07/07.
//

import Foundation

/*
 ## Challenges
 - How to I supply an interface into the networking stack when the staic is static...
 - It would be nice to get rid of the 'BLOCKv.client static stuff and pass and instance of the client in? Does that
 make sense?
 */

/*
 Why is this not a protocol extension?
 https://medium.com/@georgetsifrikas/swift-protocols-with-default-values-b7278d3eef22
 It would help to get around the default arguments issue?
 */

final class BLOCKvRemote: RemoteInterface {
    var client: ClientProtocol
    
    // dependency injection - pass networking client in
    init(client: ClientProtocol) {
        self.client = client
    }
    
    //FIXME: The caller should be able to pass a queue in! This will prevent the queue hoping, from response-concurrent, to main, and onto the sync's private queue.
    
    //FIXME: Client will call the completion on it own concurrent queue. These may need to be dispatched back to main?
    
    func getInventoryHash(completion: @escaping (Result<String, BVError>) -> Void) {
        
        let endpoint = API.Vatom.getInventoryHash()
        
        self.client.request(endpoint) { result in
            switch result {
            case .success(let baseModel):
                DispatchQueue.main.async {
                    completion(.success(baseModel.payload.hash))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
    }
    
    func getInventoryVatomSyncNumbers(limit: Int, token: String, queue: DispatchQueue = .main, completion: @escaping (Result<InventorySyncModel, BVError>) -> Void) {
        
        let endpoint = API.Vatom.getInventoryVatomSyncNumbers(limit: limit, token: token)
        
        self.client.request(endpoint) { result in
            switch result {
            case .success(let baseModel):
                queue.async {
                    completion(.success(baseModel.payload))
                }
            case .failure(let error):
                queue.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func getInventory(id: String, page: Int, limit: Int, queue: DispatchQueue = .main, completion: @escaping (Result<UnpackedModel, BVError>) -> Void) {
        
        let endpoint = API.Vatom.getInventory(parentID: id, page: page, limit: limit)
        
        self.client.request(endpoint) { result in
            switch result {
            case .success(let baseModel):
                queue.async {
                    completion(.success(baseModel.payload))
                }
            case .failure(let error):
                queue.async {
                    completion(.failure(error))
                }
            }
        }
        
    }
    
    func getVatom(withID id: String, queue: DispatchQueue = .main, completion: @escaping (Result<VatomModel, BVError>) -> Void) {
        
        let endpoint = API.Vatom.getVatoms(withIDs: [id])
        
        self.client.request(endpoint) { result in
            switch result {
            case .success(let baseModel):
                do {
                    let unpackedModel = baseModel.payload
                    let vatom = try unpackedModel.packagedSingle()
                    queue.async {
                        completion(.success(vatom))
                    }
                } catch {
                    queue.async {
                        completion(.failure(error as! BVError)) // this is safe
                    }
                }
                
            case .failure(let error):
                queue.async {
                    completion(.failure(error))
                }
            }
        }
        
    }
    
    func getVatoms(withIDs ids: [String], queue: DispatchQueue = .main, completion: @escaping (Result<UnpackedModel, BVError>) -> Void) {
        
        let endpoint = API.Vatom.getVatoms(withIDs: ids)
        
        self.client.request(endpoint) { result in
            switch result {
            case .success(let baseModel):
                queue.async {
                    completion(.success(baseModel.payload))
                }
            case .failure(let error):
                queue.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getFaceChanges(templateIds: [String], since: Double, completion: @escaping (BaseModel<ActionChangesModel>) -> Void) {
        //
    }
    
    func getActionChanges(templateIds: [String], since: Double, completion: @escaping (BaseModel<FaceChangesModel>) -> Void) {
        //
    }
    
    func trashVatom(_ id: String, completion: @escaping (BVError?) -> Void) {
        
        let endpoint = API.Vatom.trashVatom(id)
        
        self.client.request(endpoint) { result in
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    completion(nil)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(error)
                }
            }
            
        }
        
    }

    func setParentID(ofVatoms vatoms: [VatomModel], to parentID: String, completion: @escaping (Result<VatomUpdateModel, BVError>) -> Void) {
        
        let ids = vatoms.map { $0.id }
        let payload: [String: Any] = [
            "ids": ids,
            "parent_id": parentID
        ]
        
        let endpoint = API.Vatom.updateVatom(payload: payload)
        
        BLOCKv.client.request(endpoint) { result in
            
            switch result {
            case .success(let baseModel):
                
                /*
                 # Note
                 The most likely scenario where there will be partial containment errors is when setting the parent id
                 to a container vatom of type `DefinedFolderContainerType`. That is, some children will get contained,
                 others will error out and remain unchanged.
                 */
                let updateVatomModel = baseModel.payload
                DispatchQueue.main.async {
                    // roll back only those failed containments
                    let failed = vatoms.filter { !updateVatomModel.ids.contains($0.id) }
                    // Should that be done here, or in the change processor?
                    //TODO: Rollback the failed ones.
                    completion(.success(updateVatomModel))
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    //TODO: roll back all containments
                    completion(.failure(error))
                }
            }
            
        }
        
    }
   
    func performAction(name: String, payload: [String : Any], completion: @escaping (Result<[String : Any], BVError>) -> Void) {
        
        let endpoint = API.VatomAction.custom(name: name, payload: payload)
        
        self.client.request(endpoint) { result in
            
            switch result {
            case .success(let data):
                
                do {
                    guard
                        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let payload = object["payload"] as? [String: Any] else {
                            throw BVError.modelDecoding(reason: "Unable to extract payload.")
                    }
                    // model is available
                    DispatchQueue.main.async {
                        completion(.success(payload))
                    }
                    
                } catch {
                    let error = BVError.modelDecoding(reason: error.localizedDescription)
                    completion(.failure(error))
                }
                
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
            
        }
        
    }
    
    func acquireVatom(withID id: String, completion: @escaping (Result<[String : Any], BVError>) -> Void) {
        
        let body = ["this.id": id]
        // perform the action
        self.performAction(name: "Acquire", payload: body) { result in
            completion(result)
        }
        
    }
    
    func acquirePubVariation(withID id: String, completion: @escaping (Result<[String : Any], BVError>) -> Void) {
        
        let body = ["this.id": id]
        // perform the action
        self.performAction(name: "AcquirePubVariation", payload: body) { result in
            
            completion(result)
            
        }
        
    }
    
}
