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

import os
import Foundation
import Nuke

/// A completion handler to be called when task finishes or fails.
public typealias ImageCompletion = (Result<ImageResponse, ImageError>) -> Void

public enum ImageError: Swift.Error, CustomDebugStringConvertible {
    /// Encoding access credentials failed.
    case credentialEncodingFailed

    /// Data loader failed to load image data with a wrapped error.
    case dataLoadingFailed(Swift.Error)
    /// Decoder failed to produce a final image.
    case decodingFailed
    /// Processor failed to produce a final image.
    case processingFailed

    public var debugDescription: String {
        switch self {
        case .credentialEncodingFailed: return "Failed to encode asset provider credentials."
        case let .dataLoadingFailed(error): return ImagePipeline.Error.dataLoadingFailed(error).debugDescription
        case .decodingFailed: return ImagePipeline.Error.decodingFailed.debugDescription
        case .processingFailed: return ImagePipeline.Error.processingFailed.debugDescription
        }
    }

    init(error: ImagePipeline.Error) {
        switch error {
        case .dataLoadingFailed(let err): self = .dataLoadingFailed(err)
        case .decodingFailed: self = .decodingFailed
        case .processingFailed: self = .processingFailed
        @unknown default:
            fatalError()
        }
    }
}

/// Represents and image request.
///
/// Derived from Nuke.ImageRequest. Masks the ImageRequestOptions, since this must be handled by the SDK for correct
/// caching.
public struct BVImageRequest {
    let url: URL
    let processors: [ImageProcessing]
    let priority: ImageRequest.Priority

    public init(url: URL, processors: [ImageProcessing] = [], priority: ImageRequest.Priority = .normal) {
        self.url = url
        self.processors = processors
        self.priority = priority
    }
}

public class ImageDownloader {

    //TODO: How will non-blockv images be handled?
    //TODO: Only applies to the shared pipeline.

    @discardableResult
    public static func loadBLOCKvImage(with url: URL,
                                       options: ImageLoadingOptions = ImageLoadingOptions.shared,
                                       into view: ImageDisplayingView,
                                       progress: ImageTask.ProgressHandler? = nil,
                                       completion: ImageCompletion? = nil) -> ImageTask? {

        // make request
        let request = BVImageRequest(url: url)
        return ImageDownloader.loadImage(with: request, options: options, into: view, progress: progress,
                                         completion: completion)

    }

    @discardableResult
    public static func loadImage(with request: BVImageRequest,
                                 options: ImageLoadingOptions = ImageLoadingOptions.shared,
                                 into view: ImageDisplayingView,
                                 progress: ImageTask.ProgressHandler? = nil,
                                 completion: ImageCompletion? = nil) -> ImageTask? {
        assert(Thread.isMainThread)

        do {
            // encode
            let encodedURL = try BLOCKv.encodeURL(request.url)
            // make request
            let requestOptions = ImageRequestOptions(filteredURL: request.url.absoluteString)
            let request = ImageRequest(url: encodedURL, processors: request.processors, priority: request.priority,
                                       options: requestOptions)

            // load image
            return Nuke.loadImage(with: request, options: options, into: view, progress: progress) { result in
                switch result {
                case .success(let imageResponse):
                    completion?(.success(imageResponse))
                case .failure(let error):
                    os_log("Failed to load image for URL: %@", log: .default, type: .error, error.localizedDescription)
                    completion?(.failure(ImageError(error: error)))
                }
            }

        } catch let error as ImageError {
            os_log("Failed to load image for URL: %@", log: .default, type: .error, request.url.absoluteString)
            completion?(.failure(error))
            return nil
        } catch let error as BLOCKv.URLEncodingError {
            os_log("Failed to encode image for URL: %@", log: .default, type: .error, request.url.absoluteString)
            completion?(.failure(.credentialEncodingFailed))
            return nil
        } catch {
            fatalError("Unrecognised error.")
        }

    }

}

extension Nuke.ImagePipeline {

    @discardableResult
    public func loadBLOCKvImage(with request: BVImageRequest,
                                progress: ImageTask.ProgressHandler? = nil,
                                completion: ImageCompletion? = nil) -> ImageTask? {

        do {
            // encode
            let encodedURL = try BLOCKv.encodeURL(request.url)
            // make request
            let requestOptions = ImageRequestOptions(filteredURL: request.url.absoluteString)
            let request = ImageRequest(url: encodedURL, processors: request.processors, priority: request.priority,
                                       options: requestOptions)

            // load image
            return self.loadImage(with: request, progress: progress) { result in
                switch result {
                case .success(let imageResponse):
                    completion?(.success(imageResponse))
                case .failure(let error):
                    os_log("Failed to load image for URL: %@", log: .default, type: .error, error.localizedDescription)
                    completion?(.failure(ImageError(error: error)))
                }
            }

        } catch let error as ImageError {
            os_log("Failed to load image for URL: %@", log: .default, type: .error, request.url.absoluteString)
            completion?(.failure(error))
            return nil
        } catch {
            assertionFailure("Unknown error type.")
            return nil
        }

    }

}
