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

/// Default loading view.
///
/// Shows:
/// 1. Activity indicator during loading.
internal final class DefaultLoaderView: UIView, VatomViewLoader {

    // MARK: - Properties

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return indicator
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(activityIndicator)
        activityIndicator.frame = self.bounds
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - FaceViewLoader

    func startAnimating() {
        activityIndicator.startAnimating()
    }

    func stopAnimating() {
        activityIndicator.stopAnimating()
    }

}
