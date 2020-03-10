//
//  PlatformRemote.swift
//  BLOCKv
//
//  Created by Cameron McOnie on 2019/07/07.
//

import BLOCKv

public typealias RemoteRecordID = String

public protocol RemoteRecord {}

//TODO: Look into diffable data source (ios 13 onward)

enum RemoteRecordChange<T: RemoteRecord> {
    case insert(T)
    case update(T)
    case partialUpdate(WSStateUpdateEvent) //FIXME: The partial update could also be a map (or other update)?
    case delete(RemoteRecordID)
}

enum RemoteError {
    case permanent([RemoteRecordID])
    case temporary
    
    var isPermanent: Bool {
        switch self {
        case .permanent: return true
        default: return false
        }
    }
}

/*
 `RemoteMood` is a struct representation of the JSON data. This is similar to VatomModel. It would be nice to use it,
 but due to the
 */

//protocol MoodyRemote {
//    func setupMoodSubscription()
//    func fetchLatestMoods(completion: @escaping ([RemoteMood]) -> ())
//    func fetchNewMoods(completion: @escaping ([RemoteRecordChange<RemoteMood>], @escaping (_ success: Bool) -> ()) -> ())
//    func upload(_ moods: [Mood], completion: @escaping ([RemoteMood], RemoteError?) -> ())
//    func remove(_ moods: [Mood], completion: @escaping ([RemoteRecordID], RemoteError?) -> ())
//    func fetchUserID(completion: @escaping (RemoteRecordID?) -> ())
//}

/// Interface into the platform API.
///
/// This interface gets passed into the sync coordinator. Allows the sync coordinatior to execute network requests.
/// This interface will be passed onto
///
/// This allows a level of indirection, which means the networking layer can be subsituted in at a later point.
protocol RemoteInterface {
    
    /*
     Very important:
     Remote interface returns unpacked-models. This removed the unnecessary package step.
     However, the blockv interface vending stuct models should still package.
     */
    
    /*
     Should these methods be 'dumbed down' for the purposes of the sync coordinator. Or should they match the endpoints
     - I think they should match the endpoints to the sync coordinator has full power.
     
     Design Decision:
     > Should actions and faces be packed as part of the vatom? This depends on the scheme of the model...
     A. Packaged
     ++ Simpler to manage
     ++ Fast lookups (no faults or relationship traversing)
     -- Boxed in, can make relationships etc.
     B. Unpacked
     ++ Allows relationships to be made
     ++ Flexible
     -- Harder to manage
     */
    
    /*
     Decision
     - Should the interface return unpackaged (i.e. matching the server) or packaged?
     I guess closer to the server is better.
     */
    
    /*
     Ideally, the result would complete with VatomModel (struct) conforming to `RemoteRecord` but due to the questions
     around JSON, I don't yet know how to handle it. If the JSON item is solved, this interface can be based on typed
     models (rather than untyped dictionaries).
     
     Also, how would this work with the outter wrapper objects? They would have to be
     typealias Package = (_ vaotms: [VatomModel], _ faces: [FaceModel], _ actions: [ActionModel])
     
     Should setting up the web socket be part of this? or a separate interface?
     */
    
    /// Fetches the hash value for the current user's inventory.
    ///
    /// - Parameter completion: Completion handler to call once the request is completed. Called on the main queue.
    func getInventoryHash(completion: @escaping (Result<String, BVError>) -> Void)
    
    /// Fetches the sync numbers for a set of vatoms in the current user's inventory.
    ///
    /// - Parameters:
    ///   - limit: Page size.
    ///   - token: Cursor token. Frist request should be "", subsequent requests should pass in the token returned by
    ///            the previous request.
    ///   - completion: Completion handler to call once the request is completed. Called on the main queue.
    func getInventoryVatomSyncNumbers(limit: Int, token: String, queue: DispatchQueue, completion: @escaping (Result<InventorySyncModel, BVError>) -> Void)
    
    /// Fetches the current user's inventory of vAtoms. The completion handler passes in a `UnpackedModel`. An
    /// unpacked-model contains a separate array of vatoms, faces, and actions.
    ///
    /// - Parameters:
    ///   - id: Allows you to specify the `id` of a vAtom whose children should be returned.
    ///
    ///      - If a asterics "*" is supplied all vatoms (irrespective of their containment) are returned.
    ///      - If a period "." is supplied the root inventory will be retrieved (i.e. all vAtom's without a parent) -
    ///         this is the default.
    ///      - If a vAtom ID is passed in, only the child vAtoms are returned.
    ///   - page: The number of the page for which the vAtoms are returned. If omitted or set as
    ///           zero, the first page is returned.
    ///   - limit: Defines the number of vAtoms per response page (up to 100). If omitted or set as
    ///            zero, the max number is returned.
    ///   - queue: Queue on which to call the completion handler.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    ///   - unpacked model: An unpacked-model contains a separate array of vatoms, faces, and actions. Vatoms will
    ///                     have empty `faces` and `actions` arrays.
    ///   - error: BLOCKv error.
    func getInventory(id: String, page: Int, limit: Int, queue: DispatchQueue, completion: @escaping (Result<UnpackedModel, BVError>) -> Void)
    
    /// Fetches vAtoms by providing an array of vAtom IDs. The completion handler passes in an array of
    /// `VatomModel`. The array contains *packaged* vAtoms. Packaged vAtoms have their template's configured Faces
    /// and Actions as properties.
    ///
    /// - Parameters:
    ///   - ids: Array of vAtom IDs
    ///   - queue: Queue on which to call the completion handler.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    ///   - unpacked model: An unpacked-model contains a separate array of vatoms, faces, and actions. Vatoms will
    ///                     have empty `faces` and `actions` arrays.
    ///   - error: BLOCKv error.
    func getVatoms(withIDs ids: [String], queue: DispatchQueue, completion: @escaping (Result<UnpackedModel, BVError>) -> Void)
    
    //TODO: Maybe add another version of `getVatoms` which returns packaged VatomModels?
    
    /// Fetches a vAtom by providing a vAtom ID. The completion handler passes in a `VatomModel` in the *packaged* form.
    /// Packaged vAtoms have their template's configured Faces and Actions as properties.
    ///
    /// - Parameters:
    ///   - ids: Array of vAtom IDs
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    ///   - vatoms: Array of *packaged* vAtoms. Packaged vAtoms have their template's registered faces and actions
    ///     action models as populated properties.
    ///   - error: BLOCKv error.
    func getVatom(withID id: String, queue: DispatchQueue, completion: @escaping (Result<VatomModel, BVError>) -> Void)
    
    func getFaceChanges(templateIds: [String], since: Double, completion: @escaping (BaseModel<ActionChangesModel>) -> Void)
    
    func getActionChanges(templateIds: [String], since: Double, completion: @escaping (BaseModel<FaceChangesModel>) -> Void)
    
    /// Trashes the specified vAtom.
    ///
    /// This will remove the vAtom from the current user's inventory.
    ///
    /// - Parameters:
    ///   - id: Unique identifer of the vAtom.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    func trashVatom(_ id: String, completion: @escaping (BVError?) -> Void)
    
    /// Sets the parent ID of the specified vatom.
    ///
    /// - Parameters:
    ///   - vatom: Vatom whose parent ID must be set.
    ///   - parentID: Unique identifier of the parent vatom.
    ///   - completion: The completion hanlder to call when the request is completed.
    ///                 This handler is executed on the main thread.
    func setParentID(ofVatoms vatoms: [VatomModel], to parentID: String,
                     completion: @escaping (Result<VatomUpdateModel, BVError>) -> Void)
    
    // MARK: - Actions
    
    /// Performs an action on the BLOCKv platform.
    ///
    /// This is the most flexible of the action calls and should be used as a last resort.
    ///
    /// - Parameters:
    ///   - name: Name of the action to perform, e.g. "Drop".
    ///   - payload: Body payload that will be sent as JSON in the request body.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    func performAction(name: String,
                       payload: [String: Any],
                       completion: @escaping (Result<[String: Any], BVError>) -> Void)
    
    /// Performs an acquire action on the specified vatom id.
    ///
    /// Often, only a vAtom's ID is known, e.g. scanning a QR code with an embeded vAtom
    /// ID. This call is useful is such circumstances.
    ///
    /// - Parameters:
    ///   - id: The id of the vAtom to acquire.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    func acquireVatom(withID id: String,
                      completion: @escaping (Result<[String: Any], BVError>) -> Void)
    
    /// Performs an acquire pub variation action on the specified vatom id.
    ///
    /// - Parameters:
    ///   - id: The id of the vAtom to acquire.
    ///   - completion: The completion handler to call when the action is completed.
    ///                 This handler is executed on the main queue.
    func acquirePubVariation(withID id: String,
                             completion: @escaping (Result<[String: Any], BVError>) -> Void)
    
}

