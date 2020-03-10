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

import Foundation

//swiftlint:disable identifier_name

extension ActionModel: Descriptable {

    init(from descriptor: [String: Any]) throws {

        guard
            let _compoundName = descriptor["name"] as?  String,
            let _metaDescriptor = descriptor["meta"] as? [String: Any]
            else { throw BVError.modelDecoding(reason: "Model decoding failed.") }

        let (templateID, actionName) = try ActionModel.splitCompoundName(_compoundName)
        let meta = try MetaModel(from: _metaDescriptor)

        self.init(compoundName: _compoundName,
                  name: actionName,
                  templateID: templateID,
                  meta: meta)

    }

}
