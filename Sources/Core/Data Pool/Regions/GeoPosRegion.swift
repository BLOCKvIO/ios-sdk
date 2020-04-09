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

import os
import Foundation
import PromiseKit
import CoreLocation
import MapKit

/*
 - Map must have it's own array of on-screen vatom array model (which is only those vatoms for the visible region).
 - When visialble regions changes, the previous region must close, and a new region created.
 - Once the new region is created, the region's vatoms must be diffed with the in-memory model.
 This means the in-memory model only holds the on-screen vatoms, but as the region changes, remaining vatoms
 arn't removed and re-added. This could be achived with the map's annotation model.
 */

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

    /// Current user ID.
    let currentUserID = DataPool.sessionInfo["userID"] as? String ?? ""

    /// Constructor.
    required init(descriptor: Any) throws { //TODO: Add filter "all" "avatar"

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
            filter: "vatoms")

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
        BLOCKv.socket.monitorRegion(region)
    }

    /// Called on Web socket message.
    ///
    /// Allows super to handle 'state_update', then goes on to process 'inventory' events.
    /// Message process is paused for 'inventory' events which indicate a vatom was added. Since the vatom must
    /// be fetched from the server.
    override func processMessage(_ msg: [String: Any]) {

        // get info
        guard
            let msgType = msg["msg_type"] as? String,
            let payload = msg["payload"] as? [String: Any] else { return }

        if msgType == "state_update" {
            processStateUpdateMessage(msg: msg, payload: payload)
        } else if msgType == "inventory" {
            processInventoryMessage(payload: payload)
        } else if msgType == "map" {
            processMapMessage(payload: payload)
        }

    }

    /// Process state update message.
    private func processStateUpdateMessage(msg: [String: Any], payload: [String: Any]) {

        guard
            let newData = payload["new_object"] as? [String: Any],
            let vatomID = payload["id"] as? String else { return }

        // check update is related to drop
        guard let properties = newData["vAtom::vAtomType"] as? [String: Any],
            let dropped = properties["dropped"] as? Bool
            else {
                super.processMessage(msg)
                return
        }

        // check if vatom was picked up
        if !dropped {
            // remove vatom from this region
            self.remove(ids: [vatomID])
            return
        }

        // check if we have the vatom
        if self.get(id: vatomID) != nil {
            // ask super to process the update to the object (i.e. setting dropped to true)
            super.processMessage(msg)
        } else {

            // pause this instance's message processing and fetch vatom payload
            self.pauseMessages()

            // create endpoint over void
            let endpoint: Endpoint<Void> = API.Generic.getVatoms(withIDs: [vatomID])
            BLOCKv.client.request(endpoint).done { data in

                // convert
                guard
                    let object = try? JSONSerialization.jsonObject(with: data),
                    let json = object as? [String: Any],
                    let payload = json["payload"] as? [String: Any] else {
                        throw NSError.init("Unable to load") //FIXME: Create a better error
                }

                // parse out objects
                guard let items = self.parseDataObject(from: payload) else {
                    throw NSError.init("Unable to parse data") //FIXME: Create a better error
                }

                // add new objects
                self.add(objects: items)

                }.catch { error in
                    os_log("[%@] Failed to fetch vatom: %@ error: %@", log: .dataPool, type: .error, typeName(self),
                           vatomID, error.localizedDescription)
                }.finally {
                    // resume WebSocket processing
                    self.resumeMessages()
            }

        }

    }

    /// Process inventory message.
    private func processInventoryMessage(payload: [String: Any]) {

        // inspect inventory events
        guard
            let vatomID = payload["id"] as? String,
            let oldOwner = payload["old_owner"] as? String,
            let newOwner = payload["new_owner"] as? String else { return }

        /*
         Iventory events indicate a vatom has entered or exited the user's inventory. It is unlikely that dropped
         vatoms will experience inventory events, but it is possible.
         Here we check only for outgoing inventory events (e.g. transfer). This gives the listener (e.g. map) the
         opportinity to remove the vatom.
         Incomming events don't need to be processed, since the user will subsequently need to drop the vatom. This
         state-update event will be caught by the superclass `BLOCKvRegion`.
         */

        // check if this is an incoming or outgoing vatom
        if oldOwner == self.currentUserID && newOwner != self.currentUserID {
            // vatom is no longer owned by us
            self.remove(ids: [vatomID])
        }

    }

    /// Process map message.
    private func processMapMessage(payload: [String: Any]) {

        guard let operation = payload["op"] as? String, let vatomID = payload["vatom_id"] as? String else {
            return
        }

        // check operation type
        if operation == "add" {

            // create endpoint over void
            let endpoint: Endpoint<Void> = API.Generic.getVatoms(withIDs: [vatomID])
            BLOCKv.client.request(endpoint).done { data in

                // convert
                guard
                    let object = try? JSONSerialization.jsonObject(with: data),
                    let json = object as? [String: Any],
                    let payload = json["payload"] as? [String: Any] else {
                        throw RegionError.failedParsingResponse
                }

                // parse out objects
                guard let items = self.parseDataObject(from: payload) else {
                    throw RegionError.failedParsingObject
                }

                // add new objects
                self.add(objects: items)

            }.catch { error in
                os_log("[%@] Failed to fetch vatom: %@ error: %@", log: .dataPool, type: .error, typeName(self),
                       vatomID, error.localizedDescription)
            }

        } else if operation == "remove" {
            self.remove(ids: [vatomID])
        }

    }

}

public extension MKCoordinateRegion {

    /*
     Things to check:
     1. Behaviour around the poles and international date line.
     2. Potentially better way:
     > https://stackoverflow.com/q/8496551/3589408
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
