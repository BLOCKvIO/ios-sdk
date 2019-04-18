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

/// This region plugin provides access to a collection of vatoms that has been dropped within the specified region on
/// the map.
////
/// To get an instance, call `DataPool.region(id: "geopos", descriptor: MKCoordinateRegion)`
///
/// Responsibilities
/// - Monitor a region.
/// - Automatically subcribe to premptive brian updates.
class GeoPosRegion: BLOCKvRegion {

    /// Plugin identifier.
    override class var id: String { return "geopos" }

    /// The monitored region.
    let region: MKCoordinateRegion

    /// Constructor.
    required init(descriptor: Any) throws {

        // check descriptor type
        guard let region = descriptor as? MKCoordinateRegion else {
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

        var hasher = Hasher()
        hasher.combine(self.region.topRight.latitude)
        hasher.combine(self.region.topRight.longitude)
        hasher.combine(self.region.bottomLeft.latitude)
        hasher.combine(self.region.bottomLeft.longitude)
        let hash = hasher.finalize() //  not guaranteed to be equal across different executions of your program

        return "geopos:\(hash)"
    }

    /// Check if a region request matches our region.
    override func matches(id: String, descriptor: Any) -> Bool {

        // make sure we got passed a proper region object
        guard let region = descriptor as? MKCoordinateRegion else {
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

    /// Load current state from the server.
    override func load() -> Promise<[String]?> {

        // pause websocket events
        self.pauseMessages()

        let endpoint: Endpoint<Void> = API.Generic.geoDiscover(
            bottomLeftLat: self.region.bottomLeft.latitude,
            bottomLeftLon: self.region.bottomLeft.longitude,
            topRightLat: self.region.topRight.latitude,
            topRightLon: self.region.topRight.longitude,
            filter: "all")

        // execute request
        return BLOCKv.client.requestJSON(endpoint).map { json -> [String]? in

            // parse items
            guard
                let json = json as? [String: Any],
                let payload = json["payload"] as? [String: Any],
                let items = self.parseDataObject(from: payload) else {
                throw NSError.init("Unable to load") //FIXME: Create a better error
            }
            // add all objects
            self.add(objects: items)
            // return IDs
            return items.map { $0.id }

        }.ensure {

            // resume websocket events
            self.resumeMessages()

        }

    }

    /// Override save with a blank implementation. Regions change too often.
    override func save() {}

    /// Override map so we can exclude vatoms which are no longer dropped.
    override func map(_ object: DataObject) -> Any? {

        // check if dropped
        guard
            let vatom = object.data,
            let props = vatom["vAtom::vAtomType"] as? [String: Any],
            let dropped = props["dropped"] as? Bool, dropped
            else { return nil }

        // it is, continue
        return super.map(object)

    }

    /// Called when the Web socket reconnects.
    override func onWebSocketConnect() {
        super.onWebSocketConnect()

        // send region command
        self.sendRegionCommand()

    }

    /// Sends the monitor command to the backend. This allows this client to receive preemptive brain updates over the
    /// Web socket.
    func sendRegionCommand() {
        // write region command
        BLOCKv.socket.writeRegionCommand(region.toDictionary())
    }

}

private extension MKCoordinateRegion {

    /// Returns a dictionary in data pool format.
    func toDictionary() -> [String: Any] {
        let payload: [String: [String: Any]] = [
            "top_left": [
                "lat": self.topLeft.latitude,
                "lon": self.topLeft.longitude
            ],
            "bottom_right": [
                "lat": self.bottomRight.latitude,
                "lon": self.bottomRight.longitude
            ]
        ]
        return payload
    }

}

public extension MKCoordinateRegion {

    /*
     Things to check:
     1. Behaviour around the poles and international date line.
     2. Potentially better way:
     > https://stackoverflow.com/questions/8496551/how-to-fit-a-certain-bounds-consisting-of-ne-and-sw-coordinates-into-the-visible
     */

    /// Computes the coordinate of the bottom left point.
    var bottomLeft: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(
            self.center.latitude - self.span.latitudeDelta/2, self.center.longitude - self.span.longitudeDelta/2
        )
    }

    /// Computes the coordinate of the bottom right point.
    var bottomRight: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(
            self.center.latitude - self.span.latitudeDelta/2, self.center.longitude + self.span.longitudeDelta/2
        )
    }

    /// Computes the coordinate of the top right point.
    var topRight: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(
            self.center.latitude + self.span.latitudeDelta/2, self.center.longitude + self.span.longitudeDelta/2
        )
    }

    /// Computes the coordinate of the top left point.
    var topLeft: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(
            self.center.latitude + self.span.latitudeDelta/2, self.center.longitude - self.span.longitudeDelta/2
        )
    }

}
