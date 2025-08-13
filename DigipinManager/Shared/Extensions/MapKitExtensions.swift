//
//  MapKitExtensions.swift
//  DigipinManager
//
//  Created by Rishi Singh on 13/08/25.
//

import MapKit

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
