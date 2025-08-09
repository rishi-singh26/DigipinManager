//
//  AddressUtility.swift
//  DigipinManager
//
//  Created by Rishi Singh on 09/08/25.
//

import Foundation
import CoreLocation
import MapKit

class AddressUtility {
    static let shared = AddressUtility()
    
    private let geocoder = CLGeocoder()
    
    private init () {}
    
    // MARK: - Address Search
    func searchAddress(_ query: String) async throws -> [AddressSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // Optionally limit search to current location area
        // if let location = location {
        //     request.region = MKCoordinateRegion(
        //         center: location.coordinate,
        //         latitudinalMeters: 50000, // 50km radius
        //         longitudinalMeters: 50000
        //     )
        // }
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        let results = response.mapItems.compactMap { mapItem -> AddressSearchResult? in
            guard let name = mapItem.name,
                  let _ = mapItem.placemark.location else { return nil }
            
            let subtitle = [
                mapItem.placemark.thoroughfare,
                mapItem.placemark.locality,
                mapItem.placemark.administrativeArea
            ].compactMap { $0 }.joined(separator: ", ")
            
            return AddressSearchResult(
                id: UUID().uuidString,
                title: name,
                subtitle: subtitle,
                coordinate: mapItem.placemark.coordinate,
                placemark: mapItem.placemark
            )
        }
        
        let searchResults = Array(results.prefix(15)) // Limit to 15 results
        print(searchResults.count)
        
        return searchResults
    }
    
    // MARK: - Reverse Geocoding
    func getAddressFromLocation(_ location: Coordinate) async throws -> (AddressSearchResult?, String?) {
        return try await getAddressFromLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
    }
    
    func getAddressFromLocation(_ location: CLLocationCoordinate2D) async throws -> (AddressSearchResult?, String?) {
        return try await getAddressFromLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
    }
    
    func getAddressFromLocation(_ location: CLLocation) async throws -> (AddressSearchResult?, String?) {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            return (nil, nil)
        }
        
        let formattedAddress = AddressUtility.formatAddress(from: placemark)
        
        // Create title from most specific location info
        let title = placemark.name ??
        placemark.thoroughfare ??
        placemark.locality ??
        placemark.administrativeArea ??
        "Unknown Location"
        
        // Create subtitle from remaining address components
        var subtitleComponents: [String] = []
        
        if let thoroughfare = placemark.thoroughfare, title != thoroughfare {
            subtitleComponents.append(thoroughfare)
        }
        
        if let locality = placemark.locality, title != locality {
            subtitleComponents.append(locality)
        }
        
        if let state = placemark.administrativeArea, title != state {
            subtitleComponents.append(state)
        }
        
        let subtitle = subtitleComponents.isEmpty ? formattedAddress : subtitleComponents.joined(separator: ", ")
        
        let result = AddressSearchResult(
            id: UUID().uuidString,
            title: title,
            subtitle: subtitle,
            coordinate: location.coordinate,
            placemark: placemark
        )
        
        return (result, formattedAddress)
    }
    
    // MARK: - Address Formatting
    static func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            addressComponents.append(streetNumber)
        }
        
        if let streetName = placemark.thoroughfare {
            addressComponents.append(streetName)
        }
        
        let streetAddress = addressComponents.joined(separator: " ")
        
        var fullAddress: [String] = []
        
        if !streetAddress.isEmpty {
            fullAddress.append(streetAddress)
        }
        
        if let city = placemark.locality {
            fullAddress.append(city)
        }
        
        if let state = placemark.administrativeArea {
            fullAddress.append(state)
        }
        
        if let postalCode = placemark.postalCode {
            fullAddress.append(postalCode)
        }
        
        if let country = placemark.country {
            fullAddress.append(country)
        }
        
        return fullAddress.joined(separator: ", ")
    }
}
