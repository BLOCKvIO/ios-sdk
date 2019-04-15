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

func BVTimeBlock(_ block: () -> Void) -> TimeInterval {
    var info = mach_timebase_info()
    guard mach_timebase_info(&info) == KERN_SUCCESS else { return -1 }

    let start = mach_absolute_time()
    block()
    let end = mach_absolute_time()

    let elapsed = end - start
    let nanos = elapsed * UInt64(info.numer) / UInt64(info.denom)
    return TimeInterval(nanos) / TimeInterval(NSEC_PER_SEC)
}
