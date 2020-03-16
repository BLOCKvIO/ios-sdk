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

// Adapted from: https://github.com/kean

enum DelayOption {
    /// Zero delay.
    case immediate
    /// Constant delay.
    case constant(time: Double)
    /// Exponential backoff delay.
    case exponential(initial: Double, base: Double, maxDelay: Double)
    /// Custom delay where `attempt` is the itteration count.
    case custom(closure: (_ attempt: Int) -> Double)
}

extension DelayOption {

    /// Returns a delay computed as a function of some iteration counter.
    func make(_ attempt: Int) -> Double {
        switch self {
        case .immediate: return 0.0
        case .constant(let time): return time
        case .exponential(let initial, let base, let maxDelay):
            // for first attempt, simply use initial delay, otherwise calculate delay
            let delay = attempt == 1 ? initial : initial * pow(base, Double(attempt - 1))
            return min(maxDelay, delay)
        case .custom(let closure): return closure(attempt)
        }
    }

}
