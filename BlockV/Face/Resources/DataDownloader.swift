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

public protocol Cancellable: class {
    func cancel()
}

public protocol DataDownloading {

    /// - Parameters:
    ///   - url: Request URL.
    ///   - destination: Destination directory.
    ///   - progress: Progress value.
    ///   - completion: Must be called once after all (or none in case
    /// of an error) `didFinishDownloadingTo` has been called.
    /// - Returns: Cancellable item.
    func downloadData(url: URL,
                      destination: @escaping DataDownloader.Destination,
                      progress: @escaping (NSNumber) -> Void,
                      completion: @escaping (Result<URL, Swift.Error>) -> Void) -> Cancellable
}

extension URLSessionTask: Cancellable {}

public class DataDownloader: DataDownloading {

    // MARK: - Session

    public let session: URLSession
    private let _impl: _DataDownloader

    public static var recommendedCacheDirectory: URL {

        let directory = FileManager.SearchPathDirectory.cachesDirectory
        let domain = FileManager.SearchPathDomainMask.userDomainMask

        let directoryURLs = FileManager.default.urls(for: directory, in: domain)

        let destinationURL = directoryURLs.first!
            .appendingPathComponent("face_data")
            .appendingPathComponent("resources")
        return destinationURL
    }

    /// A closure executed once a download request has successfully completed in order to determine where to move the
    /// temporary file written to during the download process. The closure takes two arguments: the temporary file URL
    /// and the
    public typealias Destination = (_ temporaryURL: URL) -> URL //, options: Options)

    /// Create a download file destination closure which uses the default file manager to move the temporary file to a
    /// file URL in the recommended face directory `face_data/resources/`. Placing downloads in this file gives all
    /// faces the opportunity to share the on disk cache.
    ///
    /// - Returns: The `Destination` closure.
    public static let recommenedDestination: Destination = { (url: URL) in

        let hash = url.path.md5

        return recommendedCacheDirectory
            .appendingPathComponent(hash)
            .appendingPathComponent(url.lastTwoPathComponents)

    }

    /// Returns a default configuration which has a `nil` set as a `urlCache`.
    public static var defaultConfiguration: URLSessionConfiguration {
        let conf = URLSessionConfiguration.default
        conf.urlCache = nil // cache is on disk
        return conf
    }

    /// Validates `HTTP` responses by checking that the status code is 2xx. If
    /// it's not returns `DataLoader.Error.statusCodeUnacceptable`.
    public static func validate(response: URLResponse) -> Swift.Error? {
        guard let response = response as? HTTPURLResponse else { return nil }
        return (200..<300).contains(response.statusCode) ? nil : Error.statusCodeUnacceptable(response.statusCode)
    }

    /// Initializes `DataDownloader` with the given configuration.
    init(configuration: URLSessionConfiguration = DataDownloader.defaultConfiguration,
         validate: @escaping (URLResponse) -> Swift.Error? = DataDownloader.validate ) {
        _impl = _DataDownloader()
        //FIXME: Nuke uses a separate queue
        self.session = URLSession(configuration: configuration, delegate: _impl, delegateQueue: _impl.queue)
        self._impl.session = self.session
        self._impl.validate = validate
    }

    public func downloadData(url: URL, destination: @escaping DataDownloader.Destination,
                             progress: @escaping (NSNumber) -> Void,
                             completion: @escaping (Result<URL, Swift.Error>) -> Void) -> Cancellable {
        return _impl.downloadData(url: url, destination: destination, progress: progress, completion: completion)
    }

    /// Errors produced by `DataLoader`.
    public enum Error: Swift.Error, CustomDebugStringConvertible {
        /// Validation failed.
        case statusCodeUnacceptable(Int)

        public var debugDescription: String {
            switch self {
            case let .statusCodeUnacceptable(code): return "Response status code was unacceptable: " + code.description
            }
        }
    }

}

// MARK: - Implementation

/// DataDownloader implementation.
private final class _DataDownloader: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {

    weak var session: URLSession! // this is safe
    var validate: (URLResponse) -> Swift.Error? = DataDownloader.validate
    let queue = OperationQueue()

    private var handlers = [URLSessionTask: _Handler]()

    override init() {
        self.queue.maxConcurrentOperationCount = 1
    }

    // MARK: - Methods

    public func downloadData(url: URL,
                             destination: @escaping DataDownloader.Destination,
                             progress: @escaping (NSNumber) -> Void,
                             completion: @escaping (Result<URL, Error>) -> Void) -> Cancellable {

        let downloadTask = session.downloadTask(with: url)
        let handler = _Handler(url: url, destination: destination, progress: progress, completion: completion)
        queue.addOperation {
            self.handlers[downloadTask] = handler
        }
        downloadTask.resume()
        return downloadTask

    }

    // MARK: URLSession Delegate

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handler = handlers[task] else { return }
        handlers[task] = nil
        guard let error = error else { return }
        handler.completion(.failure(error))
    }

    // MARK: - URLSessionDownload Delegate

    //TODO: Implement
    //    func urlSession(_ session: URLSession,
    //                    downloadTask: URLSessionDownloadTask,
    //                    didWriteData bytesWritten: Int64,
    //                    totalBytesWritten: Int64,
    //                    totalBytesExpectedToWrite: Int64) {
    //
    //
    //        guard let handler = handlers[downloadTask] else { return }
    //
    //        // compute progress
    //        let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
    //        DispatchQueue.main.async {
    //            NSNumber(value: calculatedProgress)
    //        }
    //
    //    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        guard let handler = handlers[downloadTask], let response = downloadTask.response else { return }

        if let error = validate(response) {
            handler.completion(.failure(error))
            return
        }

        do {

            let destinationURL = handler.destinationURL

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                // in this case it should not have been re-downloaded, but return anyway
                handler.completion(.success(destinationURL))
            } else {
                // create directory
                try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
                // move from temp to final url
                try FileManager.default.moveItem(at: location, to: destinationURL)
                handler.completion(.success(destinationURL))
            }

        } catch {
            handler.completion(.failure(error))
        }

    }

    // MARK: - Helper

    private final class _Handler {

        let destinationURL: URL
        let completion: (Result<URL, Error>) -> Void

        init(url: URL,
             destination: @escaping DataDownloader.Destination = DataDownloader.recommenedDestination,
             progress: @escaping (NSNumber) -> Void,
             completion: @escaping (Result<URL, Error>) -> Void) {

            self.destinationURL = destination(url)
            self.completion = completion
        }
    }
}

fileprivate extension URL {

    /// The last two components of the path, or an empty string if there are less than two compoenents.
    ///
    /// If the URL has less than two path components
    var lastTwoPathComponents: String {

        if self.pathComponents.count > 2 {
            let last = self.lastPathComponent
            let secondLast = self.deletingLastPathComponent().lastPathComponent
            return secondLast + "/" + last
        } else {
            return ""
        }

    }

}
