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
import AVFoundation

extension UIImageView {

    /// Returns the size of an aspect fit image inside its image view.
    var contentClippingRect: CGRect {
        guard let image = self.image else { return self.bounds }
        return AVMakeRect(aspectRatio: image.size, insideRect: self.bounds)
    }

}

extension BaseFaceView {

    /// Size of the bounds of the view in pixels.
    public var pixelSize: CGSize {
        get {
            return CGSize(width: self.bounds.size.width * UIScreen.main.scale,
                          height: self.bounds.size.height * UIScreen.main.scale)
        }
    }

}
