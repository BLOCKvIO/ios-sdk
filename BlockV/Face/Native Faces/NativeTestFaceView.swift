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

/// Native test face view
///
/// This face is soley meant for testing the funcitonality of native faces.
class NativeTestFaceView: UIView, FaceView {

    // MARK: - Outlets

    @IBOutlet var contentView: UIView! // where nib is loaded into

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var imageView: UIImageView!

    @IBAction func showErrorButton(sender: UIButton) {
        // inform vatom view of the error

    }

    // MARK: - Fave View Protocol

    let displayURL: String = "native://test"

    /*
     To allow init?(coder aDecoder) using .xibs or storyboards, `vatomPack` and `selectedFace` must be optional.
     This is because all properties must be initialised before super is called.
     
     Do we make vatomPack, and selectedFace optional (this sucks)
     or do we disallow visual face construction? Also not great.
     */

    var vatomPack: VatomPackModel

    var selectedFace: FaceModel

    // MARK: - Initialization

    /*
     FIXME: In the generic viewer, the procedure is not passed in using the initialiser.
     Rather, a reference to the 'host' view VatomView is passed in. But this means that only the
     reference needs to be passed in because all the properties are available then.
     
     I am going to try without passing VatomView down.
     */
    init(vatomPack: VatomPackModel,
         selectedFace: FaceModel) {

        self.vatomPack = vatomPack
        self.selectedFace = selectedFace

        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        let view = self.loadViewFromNib()
        //        let view = NativeTestFaceView.fromNib()
        addSubview(view)
        view.frame = self.bounds

        self.backgroundColor = UIColor.red.withAlphaComponent(0.3)

        // setup image view
        imageView.frame = self.bounds
        imageView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        imageView.clipsToBounds = true

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("FaceView may only be initialized using the designated initializer.")
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

        // Grab resource

        // Download resource

    }

    func vatomUpdated(_ vatomPack: VatomPackModel) {
        print(#function)
    }

    func unload() {
        print(#function)
    }

    // MARK: -

    ///FIXME: This must become
    func doResourceStuff() {

        //let resourceId =
        let resourceURL = vatomPack.vatom.resources

    }

    func loadViewFromNib() -> UIView {
        // swiftlint:disable force_cast
        let bundle = Bundle(for: NativeTestFaceView.self)
//        let url = bundle.resourceURL?.appendingPathComponent("FaceModule.bundle")
        //let podBundleURL = bundle.url(forResource: "FaceModule", withExtension: "bundle")
//        let newBundle = Bundle.init(url: url!)
        let podBundlePath = bundle.path(forResource: "FaceModule", ofType: "bundle")
        let newBundle = Bundle(path: podBundlePath!)
        return newBundle!.loadNibNamed("NativeTestFaceView", owner: self, options: nil)![0] as! UIView
        // swiftlint:enable force_cast

    }

//    func loadViewFromNib() -> UIView {
//        // swiftlint:disable force_cast
//        let currentBundle = Bundle(for: type(of: self))
//        let faceBundleURL = currentBundle.url(forResource: "FaceModule", withExtension: "bundle")!
//        let faceBundle = Bundle(url: faceBundleURL)!
//        return faceBundle.loadNibNamed("NativeTestFaceView", owner: self, options: nil)![0] as! UIView
//        // swiftlint:enable force_cast
//
//    }

//    func loadViewFromNib() -> UIView {
//        // swiftlint:disable force_cast
//        let view = Bundle(for: type(of: self))
//        .loadNibNamed("NativeTestFaceView", owner: self, options: nil)![0] as! UIView
//        // swiftlint:enable force_cast
//        return view
//    }

//    func loadViewFromNib() -> UIView {
//        let bundle = Bundle(for: type(of: self))
//        let nib = UINib(nibName: "NativeTestFaceView", bundle: bundle)
//        // swiftlint:disable force_cast
//        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
//        // swiftlint:enable force_cast
//        return view
//    }

//    func loadViewFromNib() -> UIView {
//        // swiftlint:disable force_cast
//        return Bundle.main.loadNibNamed(nibName, owner: self, options: nil)?[0] as! UIView
//        //swiftlint:enable force_cast
//    }
//
//    var nibName: String {
//        return String(describing: type(of: self))
//    }

//    func loadViewFromNib() {
//        contentView = Bundle.main.loadNibNamed(nibName, owner: self, options: nil)?[0] as! UIView
//        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        contentView.frame = bounds
//        addSubview(contentView)
//    }

}

extension UIView {
    class func fromNib<T: UIView>() -> T {
        // swiftlint:disable force_cast
        return Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: nil, options: nil)![0] as! T
        // swiftlint:enable force_cast
    }
}
