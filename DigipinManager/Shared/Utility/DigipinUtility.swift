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
    
    static func getPinFrom(center: CLLocationCoordinate2D) throws -> String? {
        return try getPinFrom(latitude: center.latitude, longitude: center.longitude)
    }
    
    static func getPinFrom(coords: Coordinate) throws -> String? {
        return try getPinFrom(latitude: coords.latitude, longitude: coords.longitude)
    }
    
    static func getPinFrom(latitude: Double, longitude: Double) throws -> String? {
        return try digipinService.generateDIGIPIN(latitude: latitude, longitude: longitude)
    }
    
    static func getCoordinates(from pin : String) -> Coordinate? {
        return try? digipinService.coordinate(from: pin)
    }
}
