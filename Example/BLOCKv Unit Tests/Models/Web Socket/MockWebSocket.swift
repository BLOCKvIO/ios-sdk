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

struct MockWebSocket {

    static let mapEvent = """
    {
      "msg_type": "map",
      "payload": {
        "event_id": "map_83ce7912-82ea-45c4-9b91-36daa3e61234",
        "op": "add",
        "vatom_id": "83ce7912-82ea-1234-9b91-36daa3e61234",
        "action_name": "Drop",
        "lat": -33.123456789,
        "lon": 18.123456789
      }
    }
    """.data(using: .utf8)!

}
