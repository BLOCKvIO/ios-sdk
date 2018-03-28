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

/// `BVError` is the error type returned by BlockvSDK. These errors should not be
/// presented to users. Rather, they provide technical descriptions of the Platform
/// error.
///
/// It encompasses a few different types of errors, each with their own associated
/// errors or reasons.
///
/// NB: The BLOCKv Platform is in the process of unifying error codes.
/// BVError is subject to change in future releases.
public enum BVError: Error {
    
    // MARK: Cases
    
    /// Models a native swift model decoding error.
    case modelDecoding(reason: String)
    /// Models a BLOCKv platform error.
    case platformError(reason: PlatformErrorReason)
    /// Models any underlying networking library errors.
    case networkingError(error: Error)
    /// Models a custom error. This should be used in very limited circumstances.
    /// A more defined error is preferred.
    case custom(reason: String) //FIXME: Remove
    
    // MARK: Reasons
    
    /// Platform error. Associated values: `code` and `message`.
    public enum PlatformErrorReason {
        
        case tokenExpired(Int, String)
        case invalidPayload(Int, String)
        case tokenUnavailable(Int, String)
        case invalidDateFormat(Int, String)
        
        case malformedRequestBody(Int, String)
        case invalidDataValidation(Int, String)
        
        case vatomNotFound(Int, String)
        
        case cannotFindUser(Int, String)
        case authenticationFailed(Int, String)
        case invalidToken(Int, String)
        case avatarUploadFailed(Int, String)
        case unableToRetrieveToken(Int, String)
        case tokenAlreadyConfirmed(Int, String)
        case invalidVerificationCode(Int, String)
        case invalidPhoneNumber(Int, String)
        
        case unknownWithMissingCode(Int, String) //TODO: Remove. Temporary until all error responses return a code key-value pair.
        case unknown(Int, String) //TODO: Remove. All errors should be mapped.
        
        /// Init using a BLOCKv platfrom error code and message.
        init(code: Int, message: String) {
            switch code {
                
            case -1: self = .unknownWithMissingCode(code, message)
                
            case 401: self  = .tokenExpired(code, message)
            case 516: self  = .invalidPayload(code, message)
            case 521: self  = .tokenUnavailable(code, message)
            case 527: self  = .invalidDateFormat(code, message)
                
            case 1004: self = .malformedRequestBody(code, message)
            case 1041: self = .invalidDataValidation(code, message)
            
            case 1701: self = .vatomNotFound(code, message)
            
            // User management
            //case 11: self = .tokenAlreadyTaken(code, message)

            case 2030: self = .cannotFindUser(code, message)
            case 2031: self = .authenticationFailed(code, message)
            case 2032: self = .authenticationFailed(code, message)
            case 2034: self = .invalidToken(code, message)
            case 2037: self = .avatarUploadFailed(code, message)
            case 2552: self = .unableToRetrieveToken(code, message)
            case 2563: self = .tokenAlreadyConfirmed(code, message)
            case 2564: self = .invalidVerificationCode(code, message)
            case 2569: self = .invalidPhoneNumber(code, message)
            default:
                // useful for debugging
                //assertionFailure("Unhandled error: \(code) \(message)")
                self = .unknown(code, message)
            }
        }
        
    }
    
}

extension BVError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkingError(let error):
            return "Networking failed with error: \(error.localizedDescription)"
        case .platformError(let reason):
            return reason.localizedDescription
        case .modelDecoding(let reason):
            return "Model decoding failed with error: \(reason)"
        case .custom(reason: let reason):
            return reason
        }
    }
}

extension BVError.PlatformErrorReason {
    var localizedDescription: String {
        switch self {
            
        //TODO: Is there a better way to do this with pattern matching?
        case let .unknownWithMissingCode(_, message):
            return "UNKNOWN: BLOCKv Platform Error: (Missing Code) - Message: \(message)"
        case let .unknown(code, message):
            return "UNKNOWN: BLOCKv Platform Error: (\(code)) Message: \(message)"
        
        //
        case let .malformedRequestBody(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .invalidDataValidation(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
            
        //
        case let .vatomNotFound(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"

        //
        case let .cannotFindUser(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .authenticationFailed(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .tokenExpired(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .invalidToken(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .avatarUploadFailed(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .unableToRetrieveToken(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .tokenUnavailable(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .tokenAlreadyConfirmed(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .invalidVerificationCode(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .invalidPhoneNumber(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .invalidPayload(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        case let .invalidDateFormat(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"
        }
    }
    
}
