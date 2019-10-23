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

    /// Platform error. Associated values: `code` and `message`.
    public enum PlatformErrorReason: Equatable {

        //TODO: Remove. Temporary until all error responses return a code key-value pair.
        case unknownWithMissingCode(Int, String)
        case unknownAppId(Int, String)
        case unhandledAction(Int, String)
        case internalServerIssue(Int, String)
        case unauthorized(Int, String)
        case tokenExists(Int, String)
        case rateLimited(Int, String)
        case invalidAppKey(Int, String)
        case invalidPayload(Int, String)
        case tokenUnavailable(Int, String)
        case invalidDateFormat(Int, String)
        case malformedRequestBody(Int, String)
        case passwordRequired(Int, String)
        case invalidToken(Int, String)
        case invalidFormData(Int, String)
        case usernameNotFound(Int, String)
        case unverifiedAccount(Int, String)
        case vatomNotOwned(Int, String)
        case maxSharesReached(Int, String)
        case redemptionError(Int, String)
        case recipientLimit(Int, String)
        case vatomFolderEmpty(Int, String)
        case vatomNotFound(Int, String)
        case vatomPermissionAlreadyOwned(Int, String)
        case vatomPermissionCloneToSelf(Int, String)
        case unknownUserToken(Int, String)
        case insufficientPermission(Int, String)
        case authenticationFailed(Int, String)
        case avatarUploadFailed(Int, String)
        case unknownTokenId(Int, String)
        case cannotDeletePrimaryToken(Int, String)
        case tokenAlreadyConfirmed(Int, String)
        case invalidVerificationCode(Int, String)
        case unknownTokenType(Int, String)
        case invalidPhoneNumber(Int, String)
        case invalidEmailAddress(Int, String)

        case unknown(Int, String)

        /// Init using a BLOCKv platform error code and message.
        init(code: Int, message: String) {
            switch code {
            case -1:   self = .unknownWithMissingCode(code, message)
            case 2:    self = .unknownAppId(code, message)
            case 13:   self = .unhandledAction(code, message)
            case 11:   self = .internalServerIssue(code, message)

            case 401:  self = .unauthorized(code, message)
            case 409:  self = .tokenExists(code, message)
            case 429:  self = .rateLimited(code, message)

            case 513:  self = .invalidAppKey(code, message)
            case 516:  self = .invalidPayload(code, message)
            case 517:  self = .invalidPayload(code, message)
            case 521:  self = .tokenUnavailable(code, message)
            case 527:  self = .invalidDateFormat(code, message)

            case 1001: self = .unauthorized(code, message)
            case 1004: self = .malformedRequestBody(code, message)
            case 1006: self = .passwordRequired(code, message)
            case 1007: self = .invalidPhoneNumber(code, message)
            case 1008: self = .invalidToken(code, message)
            case 1010: self = .tokenAlreadyConfirmed(code, message)
            case 1012: self = .invalidFormData(code, message)
            case 1014: self = .usernameNotFound(code, message)
            case 1015: self = .unverifiedAccount(code, message)

            case 1604: self = .vatomNotOwned(code, message)
            case 1605: self = .vatomPermissionAlreadyOwned(code, message)
            case 1627: self = .maxSharesReached(code, message)
            case 1630: self = .redemptionError(code, message)
            case 1632: self = .redemptionError(code, message)
            case 1639: self = .vatomPermissionCloneToSelf(code, message)
            case 1654: self = .recipientLimit(code, message)
            case 1652: self = .vatomFolderEmpty(code, message)

            case 1701: self = .vatomNotFound(code, message)
            case 1702: self = .unknownUserToken(code, message)
            case 1703: self = .unknownUserToken(code, message)
            case 1705: self = .unknownUserToken(code, message)
            case 1708: self = .insufficientPermission(code, message)

            case 2030: self = .unknownUserToken(code, message)
            case 2032: self = .authenticationFailed(code, message)
            case 2037: self = .avatarUploadFailed(code, message)
            case 2553: self = .unknownTokenId(code, message)
            case 2562: self = .cannotDeletePrimaryToken(code, message)
            case 2566: self = .tokenAlreadyConfirmed(code, message)
            case 2567: self = .invalidVerificationCode(code, message)
            case 2569: self = .unknownTokenType(code, message)
            case 2571: self = .invalidEmailAddress(code, message)
            case 2572: self = .invalidPhoneNumber(code, message)

            default:
                self = .unknown(code, message)
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
        switch self {

        case let .unknownWithMissingCode(_, message):
            return "Unrecogonized: BLOCKv Platform Error: (Missing Code) - Message: \(message)"
        case let .unknown(code, message):
            return "Unrecogonized: BLOCKv Platform Error: (\(code)) - Message: \(message)"

        case let .unknownAppId(code, message),
             let .unhandledAction(code, message),
             let .internalServerIssue(code, message),
             let .unauthorized(code, message),
             let .tokenExists(code, message),
             let .rateLimited(code, message),
             let .invalidAppKey(code, message),
             let .invalidPayload(code, message),
             let .tokenUnavailable(code, message),
             let .invalidDateFormat(code, message),
             let .malformedRequestBody(code, message),
             let .passwordRequired(code, message),
             let .invalidToken(code, message),
             let .invalidFormData(code, message),
             let .usernameNotFound(code, message),
             let .unverifiedAccount(code, message),
             let .vatomNotOwned(code, message),
             let .maxSharesReached(code, message),
             let .redemptionError(code, message),
             let .recipientLimit(code, message),
             let .vatomFolderEmpty(code, message),
             let .vatomNotFound(code, message),
             let .vatomPermissionAlreadyOwned(code, message),
             let .vatomPermissionCloneToSelf(code, message),
             let .unknownUserToken(code, message),
             let .insufficientPermission(code, message),
             let .authenticationFailed(code, message),
             let .avatarUploadFailed(code, message),
             let .unknownTokenId(code, message),
             let .cannotDeletePrimaryToken(code, message),
             let .tokenAlreadyConfirmed(code, message),
             let .invalidVerificationCode(code, message),
             let .unknownTokenType(code, message),
             let .invalidPhoneNumber(code, message),
             let .invalidEmailAddress(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"

        }
    }

}
