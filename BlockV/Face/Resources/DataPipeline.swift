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

/*
 TODO:
 - Rate limiting
*/
public class DataPipeline {
    
    public static let shared = DataPipeline()
    
    /// Data loader used by the pipeline.
    public var dataDownloader: DataDownloader
    
    init(dataDownloader: DataDownloader = DataDownloader()) {
        self.dataDownloader = dataDownloader
    }
    
    public func downloadData(url: URL,
                             destination: @escaping DataDownloader.Destination = DataDownloader.recommenedDestination,
                             progress: @escaping (NSNumber) -> Void,
                             completion: @escaping (Result<URL, Error>) -> Void) -> Cancellable? {
        
        let finalURL = destination(url)
        if self.checkDiskCache(for: finalURL) {
            progress(1)
            completion(.success(finalURL))
            return nil
        } else {
            return self.dataDownloader.downloadData(url: url, destination: destination, progress: progress, completion: completion)
        }
        
    }
    
    private func checkDiskCache(for url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
}
