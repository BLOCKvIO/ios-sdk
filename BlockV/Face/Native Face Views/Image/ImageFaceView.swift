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

/// Native image face view
class ImageFaceView: UIView, FaceView {

    // MARK: - Fave View Protocol

    let displayURL: String = "native://image"

    var vatomPack: VatomPackModel

    var selectedFace: FaceModel

    // MARK: - Initialization

    init(vatomPack: VatomPackModel,
         selectedFace: FaceModel) {

        self.vatomPack = vatomPack
        self.selectedFace = selectedFace

        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        self.backgroundColor = UIColor.red.withAlphaComponent(0.3)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecylce

    override func layoutSubviews() {
        super.layoutSubviews()

        //FIXME: This should be replaced by face config

        guard let image = imageView.image else { return }

        // check scale
        if self.selectedFace.properties.constraints.viewMode == "card" {
            imageView.contentMode = .scaleAspectFill
        } else if image.size.width > imageView.bounds.size.width || image.size.height > imageView.bounds.size.height {
            imageView.contentMode = .scaleAspectFit
        } else {
            imageView.contentMode = .center
        }

    }

    // MARK: - Face View Lifecycle

    func load(completion: (Error?) -> Void) {
        print(#function)

        // Download resource

    }

    func vatomUpdated(_ vatomPack: VatomPackModel) {
        print(#function)
    }

    func unload() {
        print(#function)
    }

    // MARK: - Prototype

    ///FIXME: This must become
    func doResourceStuff() {

    }

    // FIXME: This should be of type FLAnimatedImageView
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.bounds
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.clipsToBounds = true
        return imageView
    }()

}
