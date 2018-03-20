//
//  SuccessModel.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/02/22.
//

import Foundation

/// General response model.
///
/// This model is returned on success from: logout and avatar upload.
public struct GeneralModel: Decodable {
    
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case message = "success_message"
    }
    
}
