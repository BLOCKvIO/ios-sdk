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

/// Layered image face view
class ImageLayeredFaceView: FaceView {

    class var displayURL: String { return "native://layered-image" }

	// Layer must be a class to inherit from UIImageview
	private class Layer: UIImageView {

		/// Resource this layer displays.
		var resource: VatomResourceModel?
		/// vAtom this layer displays.
		var vatom: VatomModel!

		func layerDefaultValues() {
			// Layer class defaults
			self.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
			self.clipsToBounds = true
            self.contentMode = .scaleAspectFit
		}
	}

    // MARK: - Properties

    private lazy var baseLayer: Layer = {
        let layer = Layer()
		layer.layerDefaultValues()
        return layer
    }()

    public private(set) var isLoaded: Bool = false

	private var childLayers: [Layer] = []

    private var childVatoms: [VatomModel] {
        // observer store manages the child vatoms
        return Array(vatomObserverStore.childVatoms)
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

	/*
	NOTE
	The `vatomChanged()` method called by `VatomView` does not handle child vatom updates.
	The `VatomObserver` class is used to receive these events. This is required for the Child Count policy type.
	*/

	/// Class responsible for observing changes related backing vAtom.
	private var vatomObserverStore: VatomObserverStore

    // MARK: - Init
    required init(vatom: VatomModel, faceModel: FaceModel) {
        // init face config
        self.config = Config(faceModel)

        // create an observer for the backing vatom
        self.vatomObserverStore = VatomObserverStore(vatomID: vatom.id)

        super.init(vatom: vatom, faceModel: faceModel)
        self.vatomObserverStore.delegate = self

		// ensure base has correct bounds with the 'parent' vAtom
		baseLayer.frame = self.bounds
		baseLayer.vatom = vatom
        self.addSubview(baseLayer)

    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

    // MARK: - Face View Lifecycle

    /// Begin loading the face view's content.
    func load(completion: ((Error?) -> Void)?) {
        print(#function)
        /*
         Business logic:
         This face is considered to be 'loaded' once the base image has been downloaded and loaded into the view.
         */
        loadBaseResource { (error) in
            self.refreshUI()
            self.vatomObserverStore.start() // FIXME: Should start still be called?
            completion?(error)
        }

        // continue loading by reloading all required data
        self.refreshData()

    }

    func vatomChanged(_ vatom: VatomModel) {
        print(#function)
		self.vatom = vatom

        self.refreshUI()

        // FIXME: VatomObserverStore should be recreated if vAtom id is different.
        // FIXME: Update UI
    }

    func unload() {
        print(#function)
		self.baseLayer.image = nil
        self.vatomObserverStore.stop()
    }

    // MARK: - Refresh

    /// Refresh the model layer (triggers a view layer update).
    private func refreshData() {
        print(#function)
        self.vatomObserverStore.refresh()
        self.refreshUI()
    }

    /// Refresh the view layer (does not refresh data layer).
    private func refreshUI() {
        print(#function)
        self.loadBaseResource(completion: nil)
        self.updateLayers()
    }

    // MARK: - Layer Management

    /// Traverses the child vatoms and ensure the layer hierarchy matches the current child vAtoms.
    ///
    /// This method uses *local* data.
    private func updateLayers() {

        print(#function)
        var newLayers: [Layer] = []
        for childVatom in self.childVatoms {

            var tempLayer: Layer!

            // investigate if the layer already exists
            for layer in self.childLayers where layer.vatom == childVatom {
                tempLayer = layer
                break
            }

            // added found layer to list or create a new one and add that
            newLayers.append(tempLayer == nil ? self.createLayer(childVatom) : tempLayer)
        }

        var layersToRemove: [Layer] = []
        for layer in self.childLayers {
            // check if added
            if newLayers.contains(where: { $0.vatom == layer.vatom }) {
                continue
            }

            layersToRemove.append(layer)
        }

        self.removeLayers(layersToRemove)

    }

	/// Create a standard Layer and add it to the base layer's subviews.
	private func createLayer(_ vatom: VatomModel) -> Layer {

		let layer  = Layer()
		layer.layerDefaultValues()
		layer.vatom = vatom

		// extract resource model
		guard let resourceModel = vatom.props.resources.first(where: { $0.name == config.imageName }) else {
			printBV(info: "Could not find child vatom resource model")
			return layer
		}

		// encode url
		guard let encodeURL = try? BLOCKv.encodeURL(resourceModel.url) else {
			printBV(info: "Could not encode child vatom resource")
			return layer
		}

		Nuke.loadImage(with: encodeURL, into: layer) { (_, _) in
			self.isLoaded = true
		}

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
				if let index = self.childLayers.index(of: layer) {
					self.childLayers.remove(at: index)
				}
				layer.removeFromSuperview()
			})

			// increase time offset
			timeOffset += 0.2
		}
	}

    // MARK: - Resources

    /// Loads the resource for the backing vAtom's "layerImage" into the base layer.
    private func loadBaseResource(completion: ((Error?) -> Void)?) {

        print(#function)

        // extract resource model
        guard let resourceModel = vatom.props.resources.first(where: { $0.name == config.imageName }) else {
            return
        }

        // encode url
        guard let encodeURL = try? BLOCKv.encodeURL(resourceModel.url) else {
            return
        }

        // load image (automatically handles reuse)
        Nuke.loadImage(with: encodeURL, into: self.baseLayer) { (_, error) in
            self.isLoaded = true
            completion?(error)
        }

    }

}

extension ImageLayeredFaceView: VatomObserverStoreDelegate {

    func vatomObserver(_ observer: VatomObserverStore, rootVatomStateUpdated: VatomModel) {
        print(#function)
        // nothing to do
    }

    func vatomObserver(_ observer: VatomObserverStore, childVatomStateUpdated: VatomModel) {
        print(#function)
        // nothing to do
    }

    func vatomObserver(_ observer: VatomObserverStore, willAddChildVatom vatomID: String) {
        print(#function)
        // nothing to do
    }

    func vatomObserver(_ observer: VatomObserverStore, didAddChildVatom childVatom: VatomModel) {
        print(#function)
        self.refreshUI()
    }

    func vatomObserver(_ observer: VatomObserverStore, didRemoveChildVatom childVatom: VatomModel) {
        print(#function)
        self.refreshUI()
    }

}
