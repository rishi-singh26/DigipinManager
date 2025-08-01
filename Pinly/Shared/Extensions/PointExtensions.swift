//
//  PointExtensions.swift
//  Pinly
//
//  Created by Rishi Singh on 01/08/25.
//

import SwiftUI
import MapKit

protocol GeoPoint {
    var latitude: Double { get }
    var longitude: Double { get }
}

extension Coordinate: GeoPoint {}
extension CLLocationCoordinate2D: GeoPoint {}
extension CLLocation: GeoPoint {
    var latitude: Double { coordinate.latitude }
    var longitude: Double { coordinate.longitude }
}

extension GeoPoint {
    func toString(precision: Int = 6) -> String {
        let format = "%.\(precision)f, %.\(precision)f"
        return String(format: format, latitude, longitude)
    }
}

