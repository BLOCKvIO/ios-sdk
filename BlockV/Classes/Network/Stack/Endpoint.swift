/*
 * Copyright (c) 2018 BlockV LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import Alamofire

// MARK: Defines

/*
 These type aliases allow a level of indirection.
 Types defined by alamofire become available without the need to types using
 Endpoint to import Alamofire.
 */
typealias Parameters = [String : Any]
typealias Path = String

// MARK: Endpoint

/// This class represents a server endpoint.
///
/// The generic `response` parameter specifies the type of the response
/// from the endpoint.
public final class Endpoint<Response> {
    
    let method: HTTPMethod
    let path: Path
    let parameters: Parameters?
    let encoding: ParameterEncoding
    
    init(method: HTTPMethod = .get,
         path: Path,
         parameters: Parameters? = nil,
         encoding: ParameterEncoding = JSONEncoding.default) { //TODO: Does it make sense for json to be the default encoding?
        
        self.method = method
        self.path = path
        self.parameters = parameters
        self.encoding = encoding
        
    }
    
}

/// Container for multiform data body part.
struct MultiformBodyPart {
    let data: Data
    let name: String
    let fileName: String
    let mimeType: String
}

/// This class represent a server endpoint to upload multipart form data.
///
/// The generic `response` parameter specifies the type of the response
/// from the endpoint.
public final class UploadEndpoint<Response> {
    
    let path: Path
    let bodyPart: MultiformBodyPart
    
    init(path: Path, bodyPart: MultiformBodyPart) {
        self.path = path
        self.bodyPart = bodyPart
    }
    
}
