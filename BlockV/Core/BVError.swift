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

// swiftlint:disable cyclomatic_complexity

/// `BVError` is the error type returned by BLOCKv SDK. These errors should not be
/// presented to users. Rather, they provide technical descriptions of the platform
/// error.
///
/// It encompasses a few different types of errors, each with their own associated
/// errors or reasons.
///
/// NB: The BLOCKv platform is in the process of unifying error codes.
/// BVError is subject to change in future releases.
public enum BVError: Error {

    // MARK: Cases

    /// Models a native swift model decoding error.
    case modelDecoding(reason: String)
    /// Models a BLOCKv platform error.
    case platform(reason: PlatformErrorReason)
    /// Models any underlying networking library errors.
    case networking(error: Error)
    /// Models a Web socket error.
    case webSocket(error: WebSocketErrorReason)
    /// Models a session error.
    case session(reason: SessionErrorReason)
    /// Models a custom error. This should be used in very limited circumstances.
    /// A more defined error is preferred.
    case custom(reason: String)

    // MARK: Reasons

    public enum SessionErrorReason: Equatable {
        case oauthFailed
        case invalidAuthorizationCode
        case nonMatchingStates
    }

    /// Platform errors are mapped to Enum cases. This provides a level of indirection since many platform errors may
    /// map to single logical error (at least from the Viewer's perspective).
    ///
    /// Platform error. Associated values: `code` and `message`.
    public enum PlatformErrorReason: Equatable {
        
        /*
        Conforms to error spec v1.0.0
        https://github.com/BLOCKvIO/error-spec/tree/1.0.0
        */

        case unknown(Int, String, String)
        case unknownAppId(Int, String, String)
        case unhandledAction(Int, String, String)
        case internalServerError(Int, String, String)
        case userLocationChangeLimit(Int, String, String)
        case sessionUnauthorized(Int, String, String)
        case tokenUnavailable(Int, String, String)
        case appIdRateLimited(Int, String, String)
        case appKeyInvalid(Int, String, String)
        case invalidPayload(Int, String, String)
        case dateFormatInvalid(Int, String, String)
        case authenticationRequired(Int, String, String)
        case invalidToken(Int, String, String)
        case formDataInvalid(Int, String, String)
        case usernameUnrecognized(Int, String, String)
        case accountUnverified(Int, String, String)
        case reactorTimeout(Int, String, String)
        case vatomPermissionUnauthorized(Int, String, String)
        case vatomPermissionMaxShares(Int, String, String)
        case redemptionError(Int, String, String)
        case recipientLimit(Int, String, String)
        case vatomFolderEmpty(Int, String, String)
        case vatomNotFound(Int, String, String)
        case vatomPermissionAlreadyOwned(Int, String, String)
        case vatomPermissionCloneToSelf(Int, String, String)
        case vatomAlreadyDropped(Int, String, String)
        case accountNotFound(Int, String, String)
        case avatarUploadFailed(Int, String, String)
        case cannotDeletePrimaryToken(Int, String, String)
        case tokenAlreadyConfirmed(Int, String, String)
        case invalidVerificationCode(Int, String, String)
        case unknownTokenType(Int, String, String)
        case invalidPhoneNumber(Int, String, String)
        case invalidEmailAddress(Int, String, String)

        /// Init using a BLOCKv platform error code and message.
        init(code: Int, message: String, requestId: String) {
            switch code {
            case 2:    self = .unknownAppId(code, message, requestId)
            case 11:   self = .internalServerError(code, message, requestId)
            case 13:   self = .unhandledAction(code, message, requestId)
            case 17:   self = .userLocationChangeLimit(code, message, requestId)

            case 401:  self = .sessionUnauthorized(code, message, requestId)
            case 409:  self = .tokenUnavailable(code, message, requestId)
            case 429:  self = .appIdRateLimited(code, message, requestId)

            case 513:  self = .appKeyInvalid(code, message, requestId)
            case 516:  self = .invalidPayload(code, message, requestId)
            case 517:  self = .tokenUnavailable(code, message, requestId)
            case 521:  self = .tokenUnavailable(code, message, requestId)
            case 527:  self = .dateFormatInvalid(code, message, requestId)

            case 1001: self = .sessionUnauthorized(code, message, requestId)
            case 1004: self = .invalidPayload(code, message, requestId)
            case 1006: self = .authenticationRequired(code, message, requestId)
            case 1007: self = .invalidPhoneNumber(code, message, requestId)
            case 1008: self = .invalidToken(code, message, requestId)
            case 1010: self = .tokenAlreadyConfirmed(code, message, requestId)
            case 1012: self = .formDataInvalid(code, message, requestId)
            case 1014: self = .usernameUnrecognized(code, message, requestId)
            case 1015: self = .accountUnverified(code, message, requestId)

            case 1508: self = .reactorTimeout(code, message, requestId)

            case 1604: self = .vatomPermissionUnauthorized(code, message, requestId)
            case 1605: self = .vatomPermissionAlreadyOwned(code, message, requestId)
            case 1627: self = .vatomPermissionMaxShares(code, message, requestId)
            case 1630: self = .redemptionError(code, message, requestId)
            case 1631: self = .redemptionError(code, message, requestId)
            case 1632: self = .redemptionError(code, message, requestId)
            case 1639: self = .vatomPermissionCloneToSelf(code, message, requestId)
            case 1644: self = .vatomAlreadyDropped(code, message, requestId)
            case 1654: self = .recipientLimit(code, message, requestId)
            case 1656: self = .vatomFolderEmpty(code, message, requestId)

            case 1701: self = .vatomNotFound(code, message, requestId)
            case 1702: self = .accountNotFound(code, message, requestId)
            case 1703: self = .accountNotFound(code, message, requestId)
            case 1705: self = .accountNotFound(code, message, requestId)
            case 1708: self = .vatomPermissionUnauthorized(code, message, requestId)

            case 2030: self = .accountNotFound(code, message, requestId)
            case 2032: self = .sessionUnauthorized(code, message, requestId)
            case 2037: self = .avatarUploadFailed(code, message, requestId)
            case 2562: self = .cannotDeletePrimaryToken(code, message, requestId)
            case 2566: self = .tokenAlreadyConfirmed(code, message, requestId)
            case 2567: self = .invalidVerificationCode(code, message, requestId)
            case 2569: self = .unknownTokenType(code, message, requestId)
            case 2571: self = .invalidEmailAddress(code, message, requestId)
            case 2572: self = .invalidPhoneNumber(code, message, requestId)

            default:
                self = .unknown(code, message, requestId)
            }
        }

    }

    ///
    public enum WebSocketErrorReason: Equatable {
        case connectionFailed
        case connectionDisconnected
    }

}

extension BVError: Equatable {

    public static func == (lhs: BVError, rhs: BVError) -> Bool {
        switch (lhs, rhs) {
        case (let .modelDecoding(lhsReason), let .modelDecoding(rhsReason)):
            return lhsReason == rhsReason
        case (let .platform(lhsReason), let .platform(rhsReason)):
            return lhsReason == rhsReason
        case (.networking, .networking): //TODO: does not compare associated values
            return true
        case (let .webSocket(lhsReason), let .webSocket(rhsReason)):
            return lhsReason == rhsReason
        case (let .custom(lhsReason), let .custom(rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }

    /*
     # Example Usage
     
     ## Option 1
     
     if case let BVError.platform(reason) = error, case .unknownAppId = reason {
     print("App Id Error")
     }
     
     ## Option 2
     
     if case let BVError.platform(reason) = error {
     if case .unknownAppId(_, _) = reason {
     print("App Id Error")
     }
     }
     
     ## Option 3
     
     switch error {
     case .platform(reason: .unknownAppId(_, _)):
     print("App Id Error")
     default:
     return
     }
     */

}

extension BVError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .webSocket(let error):
            return "Web socket error: \(error.localizedDescription)"
        case .networking(let error):
            return "Networking failed with error: \(error.localizedDescription)"
        case .platform(let reason):
            return reason.localizedDescription
        case .modelDecoding(let reason):
            return "Model decoding failed with error: \(reason)"
        case .session(let reason):
            return "Session error: \(reason)"
        case .custom(reason: let reason):
            return reason
        }
    }
}

// MARK: - Localized Description

extension BVError.WebSocketErrorReason {
    var localizedDescription: String {
        switch self {
        case .connectionFailed: return "Failed to connect to the Web socket."
        case .connectionDisconnected: return "The Web socket disconnected unexpectedly."
        }
    }
}

extension BVError.PlatformErrorReason {

    var localizedDescription: String {
        if case let .unknown(code, message, requestId) = self {
            return "Unrecogonized: BLOCKv Platform Error: (\(code)) Message: \(message) Request ID: \(requestId)"
        } else {
            return """
            BLOCKv Platform Error: (\(associatedValue.code))
            Message: \(associatedValue.message)
            Request ID: \(associatedValue.requestId)
            """
        }
    }

    /// Returns the associated code and message.
    public var associatedValue: (code: Int, message: String, requestId: String) {
        switch self {
        case let .unknown(code, message, requestId):
            return (code, message, requestId)
        case let .unknownAppId(code, message, requestId):
            return (code, message, requestId)
        case let .unhandledAction(code, message, requestId):
            return (code, message, requestId)
        case let .internalServerError(code, message, requestId):
            return (code, message, requestId)
        case let .userLocationChangeLimit(code, message, requestId):
            return (code, message, requestId)
        case let .sessionUnauthorized(code, message, requestId):
            return (code, message, requestId)
        case let .tokenUnavailable(code, message, requestId):
            return (code, message, requestId)
        case let .appIdRateLimited(code, message, requestId):
            return (code, message, requestId)
        case let .appKeyInvalid(code, message, requestId):
            return (code, message, requestId)
        case let .invalidPayload(code, message, requestId):
            return (code, message, requestId)
        case let .dateFormatInvalid(code, message, requestId):
            return (code, message, requestId)
        case let .authenticationRequired(code, message, requestId):
            return (code, message, requestId)
        case let .invalidToken(code, message, requestId):
            return (code, message, requestId)
        case let .formDataInvalid(code, message, requestId):
            return (code, message, requestId)
        case let .usernameUnrecognized(code, message, requestId):
            return (code, message, requestId)
        case let .accountUnverified(code, message, requestId):
            return (code, message, requestId)
        case let .reactorTimeout(code, message, requestId):
            return (code, message, requestId)
        case let .vatomPermissionUnauthorized(code, message, requestId):
            return (code, message, requestId)
        case let .vatomPermissionMaxShares(code, message, requestId):
            return (code, message, requestId)
        case let .redemptionError(code, message, requestId):
            return (code, message, requestId)
        case let .recipientLimit(code, message, requestId):
            return (code, message, requestId)
        case let .vatomFolderEmpty(code, message, requestId):
            return (code, message, requestId)
        case let .vatomNotFound(code, message, requestId):
            return (code, message, requestId)
        case let .vatomPermissionAlreadyOwned(code, message, requestId):
            return (code, message, requestId)
        case let .vatomPermissionCloneToSelf(code, message, requestId):
            return (code, message, requestId)
        case let .vatomAlreadyDropped(code, message, requestId):
            return (code, message, requestId)
        case let .accountNotFound(code, message, requestId):
            return (code, message, requestId)
        case let .avatarUploadFailed(code, message, requestId):
            return (code, message, requestId)
        case let .cannotDeletePrimaryToken(code, message, requestId):
            return (code, message, requestId)
        case let .tokenAlreadyConfirmed(code, message, requestId):
            return (code, message, requestId)
        case let .invalidVerificationCode(code, message, requestId):
            return (code, message, requestId)
        case let .unknownTokenType(code, message, requestId):
            return (code, message, requestId)
        case let .invalidPhoneNumber(code, message, requestId):
            return (code, message, requestId)
        case let .invalidEmailAddress(code, message, requestId):
            return (code, message, requestId)
        }
    }

    /// Unique handle by which to identity the error.
    var handleString: String {
        switch self {

        case .unknown:                      return "unknown"
        case .unknownAppId:                 return "app_id_unknown"
        case .unhandledAction:              return "action_unhandled"
        case .internalServerError:          return "internal_server_error"
        case .userLocationChangeLimit:      return "user_location_change_limit"
        case .sessionUnauthorized:          return "session_unauthorized"
        case .tokenUnavailable:             return "token_unavailable"
        case .appIdRateLimited:             return "app_id_rate_limited"
        case .appKeyInvalid:                return "app_key_invalid"
        case .invalidPayload:               return "payload_invalid"
        case .dateFormatInvalid:            return "date_format_invalid"
        case .authenticationRequired:       return "authentication_required"
        case .invalidToken:                 return "token_invalid"
        case .formDataInvalid:              return "form_data_invalid"
        case .usernameUnrecognized:         return "username_unrecognized"
        case .accountUnverified:            return "account_unverified"
        case .reactorTimeout:               return "reactor_timeout"
        case .vatomPermissionUnauthorized:  return "vatom_permission_unauthorized"
        case .vatomPermissionMaxShares:     return "vatom_permission_max_shares"
        case .redemptionError:              return "vatom_redemption_failed"
        case .recipientLimit:               return "vatom_permission_recipient_limit"
        case .vatomFolderEmpty:             return "vatom_folder_empty"
        case .vatomNotFound:                return "vatom_not_found"
        case .vatomPermissionAlreadyOwned:  return "vatom_permission_already_owned"
        case .vatomPermissionCloneToSelf:   return "vatom_permission_clone_to_self"
        case .vatomAlreadyDropped:          return "vatom_already_dropped"
        case .accountNotFound:              return "account_not_found"
        case .avatarUploadFailed:           return "avatar_upload_failed"
        case .cannotDeletePrimaryToken:     return "primary_token_deletion_not_permitted"
        case .tokenAlreadyConfirmed:        return "token_already_confirmed"
        case .invalidVerificationCode:      return "token_verification_code_invalid"
        case .unknownTokenType:             return "token_type_unrecognized"
        case .invalidPhoneNumber:           return "token_phone_invalid"
        case .invalidEmailAddress:          return "token_email_invalid"
   
        }
    }

}
