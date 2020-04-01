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

import UIKit

/*
 This class attempts to solve two problems:
 
 1. Certain code needs to run *after* the initial bounds of the view are known. Example, an image may need to be
 resized before being inserted into an image-view. With autolayout or autoreszing masks, the bounds of the view may
 change after initialization.
 
 2. Animating views may be subject to bounds changes. For example, a view animating from a small size to a large size
 may need an image resized for each size.
 */

/// This view class provides a convenient way to know when the bounds of a view have been set.
open class BoundedView: UIView {

    /// Setting this value to `true` will trigger a subview layout and ensure that `layoutWithKnowBounds()` is called
    /// after the layout.
    open var requiresBoundsBasedSetup = false {
        didSet {
            if requiresBoundsBasedSetup {
                // trigger a new layout cycle
                hasCompletedLayoutSubviews = false
                self.setNeedsLayout()
            }
        }
    }

    /// Boolean value indicating whether a layout pass has been completed since `requiresBoundsBasedLayout`
    public private(set) var hasCompletedLayoutSubviews = false

    override open func layoutSubviews() {
        super.layoutSubviews()

        /*
         A major assumtion here is that once this is called, the view is 'properly' layed out. This does not account
         for view size changes.
         */

        if requiresBoundsBasedSetup && !hasCompletedLayoutSubviews {
            setupWithBounds()
            hasCompletedLayoutSubviews = true
            requiresBoundsBasedSetup = false
        }

    }

    /// Called once after `layoutSubviews` has been called (i.e. bounds are set).
    ///
    /// This function is usefull for cases where the bounds of the view are important, for example, scaling an image
    /// to the correct size.
    open func setupWithBounds() {
        // subclass should override
    }

    open func didSignificantlyLayoutSubviews() {

    }

}
