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

import UIKit

/// does this need to be sepatate from vatom view? why?
class SomeNativeFaceView: UIView, FaceView {

    // MARK: - Properties

    let displayURL: String = "native://test"

    // MARK: - Lifecycle

    func onLoad(completed: () -> Void, failed: Error?) {
        print(#function)
    }

    func onVatomUpdated(_ vatomPack: VatomPackModel) {
        print(#function)
    }

    func onUnload() {
        print(#function)
    }

    // MARK: - Initialization

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        self.backgroundColor = .red
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
