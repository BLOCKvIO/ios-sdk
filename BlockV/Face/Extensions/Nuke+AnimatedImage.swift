// The MIT License (MIT)
//
// Copyright (c) 2016-2018 Alexander Grebenyuk (github.com/kean).

import UIKit
import FLAnimatedImage
import Nuke

extension FLAnimatedImageView {
    @objc open override func display(image: Image?) {
        guard image != nil else {
            self.animatedImage = nil
            self.image = nil
            return
        }
        if let data = image?.animatedImageData {
            // Display poster image immediately
            self.image = image

            // Prepare FLAnimatedImage object asynchronously (it takes a
            // noticeable amount of time), and start playback.
            DispatchQueue.global().async {
                let animatedImage = FLAnimatedImage(animatedGIFData: data)
                DispatchQueue.main.async {
                    // If view is still displaying the same image
                    if self.image === image {
                        self.animatedImage = animatedImage
                    }
                }
            }
        } else {
            self.image = image
        }
    }
}


extension ImageRequest {
    
    /// Generates a cache key based on the specified arguments.
    func generateCacheKey(url: URL, targetSize: CGSize? = nil) -> Int {
        // create a hash for the cacheKey
        var hasher = Hasher()
        hasher.combine(url)
        if let targetSize = targetSize {
            hasher.combine(targetSize.width)
            hasher.combine(targetSize.height)
        }
        return hasher.finalize()
    }
    
}
