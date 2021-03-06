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

/// This extension groups together all BLOCKv activity requests.
extension BLOCKv {

    // MARK: - Activity

    /// Fetches the activty threads *after* the specifed cursor.
    ///
    /// - Parameters:
    ///   - cursor: Filters out all threads more recent than the cursor (useful for paging).
    ///             If omitted or set as zero, the most recent threads are returned.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func getActivityThreads(cursor: String = "",
                                          count: Int = 0,
                                          completion: @escaping (Result<ThreadListModel, BVError>) -> Void) {

        let endpoint = API.UserActivity.getThreads(cursor: cursor, count: count)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                DispatchQueue.main.async {
                    completion(.success(baseModel.payload))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }

    }

    /// Fetches the activity messages for the specified thread id and *after* the specified cursor.
    ///
    /// - Parameters:
    ///   - threadId: Unique identifier of the thread (a.k.a the `name` of the thread).
    ///   - cursor: Filters out all messages more recent than the cursor (useful for paging).
    ///             If omitted or set as zero, the most recent threads are returned.
    ///   - count: Defines the number of messages to return.
    ///            Defaults to 0 (i.e. all threads will be returned).
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func getActivityMessages(forThreadId threadId: String,
                                           cursor: String = "",
                                           count: Int = 0,
                                           completion: @escaping (Result<MessageListModel, BVError>) -> Void) {

        let endpoint = API.UserActivity.getMessages(forThreadId: threadId, cursor: cursor, count: count)

        self.client.request(endpoint) { result in

            switch result {
            case .success(let baseModel):
                // model is available
                DispatchQueue.main.async {
                    completion(.success(baseModel.payload))
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }

        }

    }

    /// Send a message to another BLOCKv user.
    ///
    /// - Parameters:
    ///   - message: Content of the message.
    ///   - userID: Unique identifier of the recipient user.
    ///   - completion: The completion handler to call when the request is completed.
    ///                 This handler is executed on the main queue.
    public static func sendMessage(_ message: String, toUserId userId: String,
                                   completion:  @escaping (BVError?) -> Void) {

        let endpoint = API.CurrentUser.sendMessage(message, toUserId: userId)

        self.client.request(endpoint) { result in

            switch result {
            case .success:
                // model is available
                DispatchQueue.main.async {
                    completion(nil)
                }
            case .failure(let error):
                // handle error
                DispatchQueue.main.async {
                    completion(error)
                }
            }

        }

    }

}
