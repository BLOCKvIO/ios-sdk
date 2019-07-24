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
import Nuke

/// Provides utilities for downloading resources.
///
/// This resouce downloader should only be used glb files. All image downloading should flow through Nuke.
public class ResourceDownloader {
    
    private static var _dataCache: DataCache?
    
    private static var dataCache: DataCache? {
        if let cache = _dataCache { return cache }
        let cache = try? DataCache(name: "io.viewer.resource_cache")
        cache?.sizeLimit = 1024 * 1024 * 300 // 300 MB
        self._dataCache = cache
        return cache
    }
    
    /// Currently running downloads.
    internal static var currentDownloads: [ResourceDownloader] = []
    
    /// Downloads the resource specified by the URL.
    public static func download(url: URL) -> ResourceDownloader {
        
        // check if currently downloading
        if let existing = currentDownloads.first(where: { $0.url == url }) {
            return existing
        }
        
        // download
        let download = ResourceDownloader(url: url)
        
        // store it in the list of current downloads
        currentDownloads.append(download)
        
        // done
        return download
        
    }
    
    /// Current state
    private var isDownloading = true
    private var error: Error?
    
    /// Currently downloading URL
    public let url: URL
    
    /// Downloaded data
    public private(set) var data: Data?
    
    public typealias CallbackComplete = (Result<Data, Error>) -> Void
    
    /// Callbacks that are called on completion.
    private var completionCallback: [CallbackComplete] = []
    
    /// Constructor
    init(url: URL) {
        
        // store URL
        self.url = url
        
        print("[3DFace] [Resource Downloader] Face requested data for: \(url.absoluteString.prefix(140))")
        
        // check cache
        if let data = ResourceDownloader.dataCache?.cachedData(for: url.cacheHash) {
            
            print("[3DFace] [Resource Downloader] Found cache data: \(data)")
            
            // done
            self.isDownloading = false
            self.error = nil
            self.data = data
            
            self.completionCallback.forEach { $0(.success(data)) }
            
            // remove callbacks
            self.completionCallback.removeAll()
            
        } else {
            
            print("[3DFace] [Resource Downloader] Downloading: \(url.absoluteString.prefix(140))")
            
            // create request, ignore local cache (since we have a manual cache).
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            
            // start download
            URLSession.shared.dataTask(with: request) { [weak self] (data, _, error) in
                
                guard let self = self else { return }
                
                // done
                self.isDownloading = false
                self.error = error
                self.data = data
                
                // check for error
                if let error = error {
                    
                    // notify failed
                    self.completionCallback.forEach { $0(.failure(error)) }
                    
                } else if let data = data {
                    
                    print("[3DFace] [Resource Downloader] Caching data with key: \(url.cacheHash)")
                    
                    // store data (async but returns syncrhonously)
                    ResourceDownloader.dataCache?.storeData(data, for: url.cacheHash)
                    
                    // notify completed
                    self.completionCallback.forEach { $0(.success(data)) }
                    
                }
                
                // remove callbacks
                self.completionCallback.removeAll()
                // remove self from currently running tasks
                ResourceDownloader.currentDownloads = ResourceDownloader.currentDownloads.filter { $0 !== self }
                
                }.resume()
        }
        
    }
    
    enum ResourceError: Error {
        case downloadFailed
    }
    
    /// Add a callback for when the download is complete.
    public func onComplete(_ callBack: @escaping CallbackComplete) {
        
        // check if done already
        if !isDownloading {
            
            // check if we have data
            if let data = self.data {
                callBack(.success(data))
            } else if let err = self.error {
                callBack(.failure(err))
            } else {
                callBack(.failure(ResourceError.downloadFailed))
            }
            
            // stop
            return
            
        }
        
        // not downloading, add to callback list
        completionCallback.append(callBack)
        
    }
    
}

private extension URL {
    
    /// Creates an MD5 hash value using the URL (after the queury components have been removed).
    var cacheHash: String {
        let absoluteTrimmedQuery = self.absoluteStringByTrimmingQuery!
        return absoluteTrimmedQuery.md5
    }
    
}

private extension URL {
    
    /// Returns the string representing the URL without query components.
    var absoluteStringByTrimmingQuery: String? {
        if var urlcomponents = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            urlcomponents.query = nil
            return urlcomponents.string
        }
        return nil
    }
}
