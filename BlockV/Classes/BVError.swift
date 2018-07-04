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
    case platformError(reason: PlatformErrorReason)
    /// Models any underlying networking library errors.
    case networkingError(error: Error)
    /// Models a Web socket error.
    case webSocketError(error: WebSocketErrorReason)

    //FIXME: REMOVE AT SOME POINT
    /// Models a custom error. This should be used in very limited circumstances.
    /// A more defined error is preferred.
    case custom(reason: String)

    // MARK: Reasons

    /// Platform error. Associated values: `code` and `message`.
    public enum PlatformErrorReason {

        case unknownAppId(Int, String)
        case internalServerIssue(Int, String)
        //
        case tokenExpired(Int, String)
        case invalidPayload(Int, String)
        case tokenUnavailable(Int, String)
        case invalidDateFormat(Int, String)
        //
        case malformedRequestBody(Int, String)
        case invalidDataValidation(Int, String)
        //
        case vatomNotFound(Int, String)
        //
        case unknownUserToken(Int, String)
        case authenticationFailed(Int, String)
        case invalidToken(Int, String)
        case avatarUploadFailed(Int, String)
        case userRefreshTokenInvalid(Int, String)
        case authenticationLimit(Int, String)
        //
        case unknownTokenType(Int, String)
        case unknownTokenId(Int, String)
        case tokenNotFound(Int, String)
        case cannotDeletePrimaryToken(Int, String)
        case unableToRetrieveToken(Int, String)
        case tokenAlreadyConfirmed(Int, String)
        case invalidVerificationCode(Int, String)
        case invalidPhoneNumber(Int, String)
        case invalidEmailAddress(Int, String)
        //TODO: Remove. Temporary until all error responses return a code key-value pair.
        case unknownWithMissingCode(Int, String)
        case unknown(Int, String) //TODO: Remove. All errors should be mapped.

        /// Init using a BLOCKv platform error code and message.
        init(code: Int, message: String) {
            switch code {
            case -1:  self = .unknownWithMissingCode(code, message)
            // App Id is unacceptable.
            case 2:   self = .unknownAppId(code, message)
            // Server encountered an error processing the request.
            case 11:  self = .internalServerIssue(code, message)
            // App Id is unacceptable.
            case 17:  self = .unknownAppId(code, message)
            // Request paylaod is invalid.
            case 516: self = .invalidPayload(code, message)
            // Request paylaod is invalid.
            case 517: self = .invalidPayload(code, message)
            // User token (phone, email) is already taken.
            case 521: self = .tokenUnavailable(code, message)
            // Date format is invalid (e.g. invalid birthday in update user call).
            case 527: self = .invalidDateFormat(code, message)
            // Invalid request payload on an action.
            case 1004: self = .malformedRequestBody(code, message)
            // vAtom is unrecognized by the platform.
            case 1701: self = .vatomNotFound(code, message)
            // User token (phone, email, id) is unrecognized by the platfrom.
            case 2030: self = .unknownUserToken(code, message)
            // Login phone/email wrong. password
            case 2032: self = .authenticationFailed(code, message)
            // Uploading the avatar data. failed.
            case 2037: self = .avatarUploadFailed(code, message)
            // Refresh token is not on the whitelist, or the token has expired.
            case 2049: self = .userRefreshTokenInvalid(code, message)
            // Too many login requests.
            case 2051: self = .authenticationLimit(code, message)
            //???
            case 2552: self = .unableToRetrieveToken(code, message)
            // Token id does not map to a token.
            case 2553: self = .unknownTokenId(code, message)
            // Primary token cannot be deleted.
            case 2562: self = .cannotDeletePrimaryToken(code, message)
            // Attempting to verfiy an already verified token.
            case 2566: self = .tokenAlreadyConfirmed(code, message)
            // Invalid verification code used when attempting to verify an account.
            case 2567: self = .invalidVerificationCode(code, message)
            // Unrecognized token type (only `phone` and `email` are currently accepted).
            case 2569: self = .unknownTokenType(code, message)
            // Invalid email address.
            case 2571: self = .invalidEmailAddress(code, message)
            // Invalid phone number.
            case 2572: self = .invalidPhoneNumber(code, message)
            default:
                // useful for debugging
                //assertionFailure("Unhandled error: \(code) \(message)")
                self = .unknown(code, message)
            }
        }

    }

    ///
    public enum WebSocketErrorReason {
        case connectionFailed
        case connectionDisconnected
    }

}

extension BVError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .webSocketError(let error):
            return "Web socket error: \(error.localizedDescription)"
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

        //TODO: Is there a better way to do this with pattern matching?
        case let .unknownWithMissingCode(_, message):
            return "Unrecogonized: BLOCKv Platform Error: (Missing Code) - Message: \(message)"
        case let .unknown(code, message):
            return "Unrecogonized: BLOCKv Platform Error: (\(code)) - Message: \(message)"

        case let .malformedRequestBody(code, message),
             let .invalidDataValidation(code, message),
             let .vatomNotFound(code, message),
             let .avatarUploadFailed(code, message),
             let .unableToRetrieveToken(code, message),
             let .tokenUnavailable(code, message),
             let .authenticationLimit(code, message),
             let .tokenAlreadyConfirmed(code, message),
             let .invalidVerificationCode(code, message),
             let .invalidPhoneNumber(code, message),
             let .invalidEmailAddress(code, message),
             let .invalidPayload(code, message),
             let .invalidDateFormat(code, message),
             let .userRefreshTokenInvalid(code, message),
             let .tokenNotFound(code, message),
             let .cannotDeletePrimaryToken(code, message),
             let .unknownAppId(code, message),
             let .internalServerIssue(code, message),
             let .tokenExpired(code, message),
             let .unknownUserToken(code, message),
             let .authenticationFailed(code, message),
             let .invalidToken(code, message),
             let .unknownTokenType(code, message),
             let .unknownTokenId(code, message):
            return "BLOCKv Platform Error: (\(code)) Message: \(message)"

        }
    }

}
