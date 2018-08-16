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

// ------------------------------------

/// Pack model holding a single vatom.
struct VatomPackModel { // SinglePackModel
    let vatom: VatomModel
    let faces: [FaceModel]
    let actions: [ActionModel]
}

// ------------------------------------

/// Responsible for displaying a vAtom face (native or Web).
class VatomView: UIView {

    // MARK: - Properties

    var selectedFace: FaceModel

    var loadingView: UIView?
    var errorView: UIView?

    //TODO: This could become PackModel.
    var vatom: VatomModel!
    var faces: [FaceModel] = []
    var actions: [ActionModel] = []

    // MARK: - Initializer

    /// Creates a vAtom view for the specifed vAtom.
    ///
    /// 
    ///
    /// - Parameters:
    ///   - vatom: The vAtom to display.
    ///   - faces: The array of faces associated with the vAtom's template.
    ///   - actions: The array of actions associated with the vAtom's template.
    ///   - procedure: An embedded (predefiened) face selection procedure that determines which face to display.
    init(vatom: VatomModel,
         faces: [FaceModel],
         actions: [ActionModel],
         procedure: EmbeddedProcedure) {

        // select best face
        selectedFace = procedure.selectBestFace(faceModels: faces)!

        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

    }

    /// Creates a vAtom view for the specifed vAtom using the provided face selection procedure.
    ///
    /// - Parameters:
    ///   - vatom: The vAtom to display.
    ///   - faces: The array of faces associated with the vAtom's template.
    ///   - actions: The array of actions associated with the vAtom's template.
    ///   - customProcedure: A function type that allows for customization of the face selection.
    init(vatom: VatomModel,
         faces: [FaceModel],
         actions: [ActionModel],
         customProcedure: FaceSelectionProcedure) {

        selectedFace = customProcedure(faces)! //FIXME: What happens if this fails?

        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))

        // ...

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {

        self.loadingView = UIView() // or custom
        self.errorView = UIView() // or custom

    }

    // MARK: - Methods

    func pickFace(vatom: VatomModel, viewContext: String) {

    }

}
