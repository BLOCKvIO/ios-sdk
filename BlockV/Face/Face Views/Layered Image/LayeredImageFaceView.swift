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

/// Native Layered face view
class LayeredImageFaceView: FaceView {
    class var displayURL: String { return "native://layered-image" }

	// Layer must be a class to inherit from UIImageview
	class Layer: UIImageView {
		// Reference to the resource this layer displays.
		var resource: VatomResourceModel?
		// Reference to the vAtom which this layer represents.
		var vatom: VatomModel!

		convenience override init(frame: CGRect) {
			self.init()

			// Layer class defaults
			self.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
			self.clipsToBounds = true
		}
	}

    // MARK: - Properties

    lazy var baseLayer: Layer = {
        let layer = Layer()
        return layer
    }()

    public private(set) var isLoaded: Bool = false

	var childVatoms: [VatomModel] = []
	var topLayers: [Layer] = []

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
                self.imageName ?= config["image"]?.stringValue
            }
        }
    }

    private let config: Config

    // MARK: - Init
    required init(vatom: VatomModel, faceModel: FaceModel) {
        // init face config
        self.config = Config(faceModel)
        super.init(vatom: vatom, faceModel: faceModel)

		//ensure base has correct bounds with the 'parent' vAtom
		baseLayer.frame = self.bounds
		baseLayer.vatom = vatom
        self.addSubview(baseLayer)

		// initial setup
		self.vAtomStateChanged()

		// listen to websocket for state changes on LayeredImageView
		BLOCKv.socket.onVatomStateUpdate.subscribe(with: self) { ( _ stateUpdateEvent) in
			self.vAtomStateChanged()
		}
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

	// MARK: - View Lifecylce

	override func layoutSubviews() {
		super.layoutSubviews()
		updateContentMode(forLayer: baseLayer)
	}

	private func updateContentMode(forLayer: Layer) {
		forLayer.contentMode = .scaleAspectFit
	}

    // MARK: - Face View Lifecycle

    /// Begin loading the face view's content.
    func load(completion: ((Error?) -> Void)?) {
		updateResources(completion: completion)
    }

    func vatomChanged(_ vatom: VatomModel) {
		self.vatom = vatom
		updateResources(completion: nil)
    }

    func unload() {
		self.baseLayer.image = nil
    }

	// MARK: - Resources

	private func updateResources(completion: ((Error?) -> Void)?) {

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

	/// Fetch the children of the given vAtom and apply the relevant layers

	func vAtomStateChanged() {
		BLOCKv.getInventory(id: self.vatom.id) { (vatomModels, error) in

			guard error == nil else {
				printBV(info: "getInventory - \(error!.localizedDescription)")
				return
			}

			self.childVatoms = vatomModels

			var newLayers: [Layer] = []
			for childVatom in self.childVatoms {

				var tempLayer: Layer!

				//investigate if the layer already exists
				for layer in self.topLayers where layer.vatom == childVatom {
					tempLayer = layer
					break
				}

				// added found layer to list or create a new one and add that
				newLayers.append(tempLayer == nil ? self.createLayer(childVatom) : tempLayer)
			}

			var layersToRemove: [Layer] = []
			for layer in self.topLayers {
				// check if added
				if newLayers.contains(where: { $0.vatom == layer.vatom }) {
					continue
				}

				layersToRemove.append(layer)
			}

			self.removeLayers(layersToRemove)
		}
	}

	// MARK: - Creation Layer

	/// Create a standard Layer and add it to the base layer's subviews
	private func createLayer(_ vatom: VatomModel) -> Layer {
		let layer  = Layer()
		self.updateContentMode(forLayer: layer)

		layer.vatom = vatom

		// extract resource model
		guard let resourceModel = vatom.props.resources.first(where: { $0.name == config.imageName }) else {
			printBV(info: "could not find child vatom resource model")
			return layer
		}

		// encode url
		guard let encodeURL = try? BLOCKv.encodeURL(resourceModel.url) else {
			printBV(info: "could not encode child vatom resource")
			return layer
		}

		Nuke.loadImage(with: encodeURL, into: layer) { (_, _) in
			self.isLoaded = true
		}

		layer.frame = self.bounds
		self.baseLayer.addSubview(layer)
		self.topLayers.append(layer)

		return layer
	}

	/// Remove layers that are not part of the vAtoms children 
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
				if let index = self.topLayers.index(of: layer) {
					self.topLayers.remove(at: index)
				}
				layer.removeFromSuperview()
			})

			// increase time offset
			timeOffset += 0.2
		}
	}
}
