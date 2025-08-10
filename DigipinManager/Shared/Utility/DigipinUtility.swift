//
//  DigipinUtility.swift
//  DigipinManager
//
//  Created by Rishi Singh on 10/08/25.
//

import Foundation
import MapKit

class DigipinUtility {
    private static let digipinService = DIGIPIN()
    
    static func getPinFrom(center: CLLocationCoordinate2D) -> String? {
        return getPinFrom(coords: Coordinate(latitude: center.latitude, longitude: center.longitude))
    }
    
    static func getPinFrom(coords: Coordinate) -> String? {
        return try? digipinService.generateDIGIPIN(latitude: coords.latitude, longitude: coords.longitude)
    }
    
    static func getCoordinates(from pin : String) -> Coordinate? {
        return try? digipinService.coordinate(from: pin)
    }
}
