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

/*
 Native Test Face View uses a .xib
 */

/// Native test face view
///
/// This face is soley meant for testing the funcitonality of native faces.
class TestFaceView: FaceView, FaceModuleNibLoadable {

    // MARK: - Outlets

    @IBOutlet var contentView: UIView? // nib is loaded into

    @IBOutlet var imageView: UIImageView!

    // MARK: - Fave View Protocol

    class var displayURL: String { return "native://test" }

    // MARK: - Initialization

    required init(vatom: VatomModel, faceModel: FaceModel) {
        super.init(vatom: vatom, faceModel: faceModel)

        self.backgroundColor = UIColor.red.withAlphaComponent(0.3)

        // load content view
        guard let view = self.fromNib() else { return }
        view.frame = self.bounds
        addSubview(view)
        self.contentView = view

        imageView.frame = self.bounds
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.blue.withAlphaComponent(0.2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("FaceView may only be initialized using the designated initializer.")
    }

    // MARK: - View Lifecylce

    override func layoutSubviews() {
        super.layoutSubviews()

    }

    // MARK: - Face View Lifecycle

    private var timer: Timer?
    
    var isLoaded: Bool = false

    func load(completion: ((Error?) -> Void)?) {
        print(#function)

        self.timer = Timer(timeInterval: 2, repeats: false) { (_) in
            completion?(nil)
        }

        // Download resource

    }

    func vatomChanged(_ vatom: VatomModel) {
        print(#function)
    }

    func unload() {
        print(#function)
    }

    // MARK: -

    ///FIXME: This must become
    func doResourceStuff() {

    }

}

protocol FaceModuleNibLoadable where Self: UIView {

    func fromNib() -> UIView?

}

extension FaceModuleNibLoadable {

    func fromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let faceBundlePath = bundle.path(forResource: "FaceModule", ofType: "bundle")
        // swiftlint:disable force_cast
        let faceBundle = Bundle(path: faceBundlePath!)
        let view = faceBundle?.loadNibNamed(String(describing: Self.self), owner: self, options: nil)![0] as! UIView
        // swiftlint:enable force_cast
        return view
    }

}

/*
 The extension below uses a generic version which may mean specialization
 at runtime - maybe the FaceModuleNiLoadable protocol should adopt this?
 */

//extension UIView {
//    class func fromNib<T: UIView>() -> T {
//        // swiftlint:disable force_cast
//        return Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: nil, options: nil)![0] as! T
//        // swiftlint:enable force_cast
//    }
//}
