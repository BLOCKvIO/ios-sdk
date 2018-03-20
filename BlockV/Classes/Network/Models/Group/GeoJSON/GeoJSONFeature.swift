//
//  GeoJSONFeature.swift
//  BlockV
//
//  Created by Cameron McOnie on 2018/03/03.
//

import Foundation
import CoreLocation

//public protocol GeoJSONFeature {
//    static var type: String { get }
//    var geometryCoordinates: [Any] { get }
//    var dictionaryRepresentation: [String: Any] { get }
//    init?(dictionary: [String: Any])
//}
//
//extension GeoJSONFeature {
//    public static var type: String { return "Feature" }
//    public var dictionaryRepresentation: [String: Any] {
//        return [
//            "geometry": [
//                "coordinates": self.geometryCoordinates,
//                "type": type(of: self).type
//            ],
//            "type": "Feature",
//            "properties": [:]
//        ]
//    }
//    public var geometryCoordinates: [Any] {
//        return []
//    }
//    public init?(dictionary: [String: Any]) {
//        return nil
//    }
//}
//
//extension Array {
//    var coordinateRepresentation: CLLocationCoordinate2D? {
//        guard self.count >= 2 else { return nil }
//        guard let latitude = self[1] as? Double, let longitude = self[0] as? Double else { return nil }
//        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
//}
//
//extension CLLocationCoordinate2D {
//    var geoJSONRepresentation: [Double] {
//        return [self.longitude, self.latitude]
//    }
//}

