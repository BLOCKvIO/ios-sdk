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
import PromiseKit
import CoreLocation
import MapKit

/// This region plugin provides access to a collection of vatoms that has been dropped within the specified region on the map.
/// To get an instance, call `DataPool.region(id: "geopos", descriptor: GeoPosRegionCoordinates(topRight: ..., bottomLeft: ...))`
class GeoPosRegion: BLOCKvRegion {
    
    /// Plugin identifier.
    override class var id : String { return "geopos" }
    
    /// The region we're monitoring.
    let region: GeoPosRegionCoordinates
    
    /// Constructor.
    required init(descriptor: Any) throws {
        
        // check descriptor type
        guard let region = descriptor as? GeoPosRegionCoordinates else {
            throw NSError("Region descriptor must be a GeoPosRegionCoordinates object!")
        }
        
        // store region
        self.region = region
        
        // setup base class
        try super.init(descriptor: descriptor)
        
        // send region command
        self.sendRegionCommand()
        
    }
    
    /// Our state key is the top-right and bottom-left geopos coordinates
    override var stateKey: String {
        return "geopos:\(self.region.topRight.latitude),\(self.region.topRight.longitude) \(self.region.bottomLeft.latitude),\(self.region.bottomLeft.longitude)"
    }
    
    /// Check if a region request matches our region
    override func matches(id : String, descriptor : Any) -> Bool {
        
        // make sure we got passed a proper region object
        guard let region = descriptor as? GeoPosRegionCoordinates else {
            return false
        }
        
        // check if matches ours
        if region.topRight.latitude == self.region.topRight.latitude &&
            region.topRight.longitude == self.region.topRight.longitude &&
            region.bottomLeft.latitude == self.region.bottomLeft.latitude &&
            region.bottomLeft.longitude == self.region.bottomLeft.longitude {
            return true
        }
        
        // did not match
        return false
        
    }
    
    /// Load current state from the server
    override func load() -> Promise<[String]?> {
        
        // pause websocket events
        self.pauseMessages()
        
        let endpoint: Endpoint<Void> = API.Vatom.geoDiscover(
            bottomLeftLat: self.region.bottomLeft.latitude,
            bottomLeftLon: self.region.bottomLeft.longitude,
            topRightLat: self.region.topRight.latitude,
            topRightLon: self.region.topRight.longitude,
            filter: "all")
                
        BLOCKv.client.request(endpoint).map { data -> [String]? in
        
        // execute request
//        return Request2.post(endpoint: "/vatom/geodiscover", payload: [
//            "top_right": [
//                "lat": self.region.topRight.latitude,
//                "lon": self.region.topRight.longitude
//            ],
//            "bottom_left": [
//                "lat": self.region.bottomLeft.latitude,
//                "lon": self.region.bottomLeft.longitude
//            ],
//            "filter": "all",
//            "limit": 10000
//            ]).then { data -> [String]? in
            
                // parse items
//                guard let items = self.parseDataObject(from: data) else {
//                    return nil
//                }
//
//                // add all objects
//                self.add(objects: items)
//
//                // return IDs
//                return items.map { $0.id }
            
//            }.always {
//
//                // resume websocket events
//                self.resumeMessages()
//
        }
        
    }
    
    /// We don't want to save these regions, they change too much
    override func save() {}
    
    /// Override map so we can exclude vatoms which are no longer dropped
    override func map(_ object : DataObject) -> Any? {
        
        // check if dropped
        guard let o1 = object.data, let o2 = o1["vAtom::vAtomType"] as? [String:Any], let dropped = o2["dropped"] as? Bool, dropped else {
            return nil
        }
        
        // it is, continue
        return super.map(object)
        
    }
    
    /// Called when the WebSocket reconnects
    override func onWebSocketConnect() {
        super.onWebSocketConnect()
        
        // send region command
        self.sendRegionCommand()
        
    }
    
    /// Informs the backend which GeoPos region we want to monitor for moving objects
    func sendRegionCommand() {
        
        // create map region
        let region = MKCoordinateRegion.init(center:
            CLLocationCoordinate2D(
                latitude: (self.region.topRight.latitude + self.region.bottomLeft.latitude) / 2,
                longitude: (self.region.topRight.longitude + self.region.bottomLeft.longitude) / 2
            ), span: MKCoordinateSpan(
                latitudeDelta: abs(self.region.topRight.latitude - self.region.bottomLeft.latitude),
                longitudeDelta: abs(self.region.topRight.longitude - self.region.bottomLeft.longitude)
            )
        )
        
        // send our region over WebSocket to the server
//        NotificationCenter.default.post(RegionEvent.startBrainUpdates.asNotification)
        
    }
    
}



public struct GeoPosRegionCoordinates {
    
    // fields
    let topRight: CLLocationCoordinate2D
    let bottomLeft: CLLocationCoordinate2D

    public init(topRight: CLLocationCoordinate2D, bottomLeft: CLLocationCoordinate2D) {
        self.topRight = topRight
        self.bottomLeft = bottomLeft
    }
    
}
