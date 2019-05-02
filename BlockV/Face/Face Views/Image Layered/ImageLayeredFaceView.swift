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
import Nuke

// Subclass of UIImageView which represents a vatom image layer.
private class Layer: UIImageView {

    /// Template variation this layer represents. Template variations all point to the same resource.
    var vatomID: String

    init(vatom: VatomModel) {
        self.vatomID = vatom.id
        super.init(frame: CGRect.zero)
        // layer class defaults
        self.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFit
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

/// Layered image face view
class ImageLayeredFaceView: FaceView {

    class var displayURL: String { return "native://layered-image" }

    // MARK: - Properties

    /// Layer used to render the base vAtom.
    private lazy var baseLayer: Layer = {
        let layer = Layer(vatom: self.vatom)
        layer.frame = self.bounds
        return layer
    }()

    public private(set) var isLoaded: Bool = false

	private var childLayers: [Layer] = []

    private var childVatoms: [VatomModel] {
        // fetch cached children
        return self.vatom.listCachedChildren()
    }

    // MARK: - Config

    /// Face model face configuration specification.
    private struct Config {

        // defaults
        var imageName: String = "ActivatedImage"

        /// Initialize using face model.
        ///
        /// The config has a set of default values. If the face config section is present, those values are used in
        /// place of the default ones.
        ///
        /// ### Legacy Support
        /// The first resource name in the resources array (if present) is used in place of the activate image.
        init(_ faceModel: FaceModel) {
            // legacy: overwrite fallback if needed
            self.imageName ?= faceModel.properties.resources.first

            if let config = faceModel.properties.config {
                self.imageName ?= config["layerImage"]?.stringValue
            }
        }
    }

    private let config: Config

    // MARK: - Init
    required init(vatom: VatomModel, faceModel: FaceModel) {
        // init face config
        self.config = Config(faceModel)

        super.init(vatom: vatom, faceModel: faceModel)

        self.addSubview(baseLayer)

    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

    // MARK: - Face View Lifecycle

    /// Begins loading the face view's content.
    func load(completion: ((Error?) -> Void)?) {

        // reset content
        self.reset()
        // load required resources
        self.loadResources { [weak self] error in

            guard let self = self else { return }

            // update ui
            self.updateLayers()

            // update state and inform delegate of load completion
            if let error = error {
                self.isLoaded = false
                completion?(error)
            } else {
                self.isLoaded = true
                completion?(nil)
            }
        }

    }

    /// Updates the backing Vatom and loads the new state.
    func vatomChanged(_ vatom: VatomModel) {

        // replace vatom
        self.vatom = vatom
        // update ui
        self.updateLayers()

    }

    /// Resets the contents of the face view.
    private func reset() {
        self.baseLayer.image = nil
        self.removeAllLayers()
    }

    /// Unload the face view (called when the VatomView must prepare for reuse).
    func unload() {
        self.reset()
        //TODO: Cancel downloads
    }

    // MARK: - Layer Management

    /// Traverses the child vatoms and ensure the layer hierarchy matches the current child vAtoms.
    ///
    /// This method uses *local* data.
    private func updateLayers() {

        var newLayers: [Layer] = []
        for childVatom in self.childVatoms {

            var tempLayer: Layer!

            // investigate if the layer already exists
            for layer in self.childLayers where layer.vatomID == childVatom.id {
                tempLayer = layer
                break
            }

            // added found layer to list or create a new one and add that
            newLayers.append(tempLayer == nil ? self.createLayer(childVatom) : tempLayer)
        }

        var layersToRemove: [Layer] = []
        for layer in self.childLayers {
            // check if added
            if newLayers.contains(where: { $0.vatomID == layer.vatomID }) {
                continue
            }

            layersToRemove.append(layer)
        }

        self.removeLayers(layersToRemove)

    }

	/// Create a standard Layer and add it to the base layer's subviews.
	private func createLayer(_ vatom: VatomModel) -> Layer {

		let layer  = Layer(vatom: vatom)

		// extract resource model
		guard let resourceModel = vatom.props.resources.first(where: { $0.name == config.imageName }) else {
			printBV(error: "Could not find child vAtom resource model.")
			return layer
		}

		// encode url
		guard let encodeURL = try? BLOCKv.encodeURL(resourceModel.url) else {
			printBV(error: "Could not encode child vAtom resource.")
			return layer
		}

        var request = ImageRequest(url: encodeURL,
                                   targetSize: pixelSize,
                                   contentMode: .aspectFit)
        // use unencoded url as cache key
        request.cacheKey = resourceModel.url
        // load image (automatically handles reuse)
		Nuke.loadImage(with: request, into: layer)

		layer.frame = self.bounds
		self.baseLayer.addSubview(layer)
		self.childLayers.append(layer)

		return layer

	}

	/// Remove layers that are not part of the vAtoms children.
	private func removeLayers(_ layers: [Layer]) {

		// remove each layer
		var timeOffset: TimeInterval = 0
		for layer in layers.reversed() {

			// animate out
			UIView.animate(withDuration: 0.25, delay: timeOffset, options: [], animations: {

				// animate away
				layer.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
				layer.alpha = 0

			}, completion: { _ in

				// remove it
				if let index = self.childLayers.firstIndex(of: layer) {
					self.childLayers.remove(at: index)
				}
				layer.removeFromSuperview()
			})

			// increase time offset
			timeOffset += 0.2
		}
	}

    /// Remove all child layers without animation.
    private func removeAllLayers() {
        childLayers.forEach { $0.removeFromSuperview() }
        childLayers = []
    }

    // MARK: - Resources

    /// Loads the resource for the backing vAtom's "layerImage" into the base layer.
    ///
    /// Calls the `loadCompletion` closure asynchronously. Note: the mechanics of `loadImage(with:into:)` mean only the
    /// latest completion handler will be executed since all previous tasks are cancelled.
    private func loadResources(completion: @escaping (Error?) -> Void) {

        // extract resource model
        guard let resourceModel = vatom.props.resources.first(where: { $0.name == config.imageName }) else {
            completion(FaceError.missingVatomResource)
            return
        }

        do {
            // encode url
            let encodeURL = try BLOCKv.encodeURL(resourceModel.url)

            var request = ImageRequest(url: encodeURL,
                                       targetSize: pixelSize,
                                       contentMode: .aspectFit)
            // use unencoded url as cache key
            request.cacheKey = resourceModel.url

            // load image (auto cancel previous)
            Nuke.loadImage(with: request, into: self.baseLayer) { (_, error) in
                self.isLoaded = true
                completion(error)
            }
        } catch {
            completion(error)
        }

    }

}
