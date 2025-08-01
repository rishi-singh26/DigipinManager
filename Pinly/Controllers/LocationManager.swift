//
//  LocationManager.swift
//  Pinly
//
//  Created by Rishi Singh on 31/07/25.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Address Search Result
struct AddressSearchResult: Identifiable {
    var id: String
    
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let placemark: CLPlacemark
}

// MARK: - LocationManager
@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var isSearching = false
    @Published var isReverseGeocoding = false
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable location access in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "Location permission not granted"
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Address Search
    func searchAddress(_ query: String) async -> [AddressSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
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
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Reverse Geocoding
    func getAddressFromLocation(_ location: Coordinate) async -> (AddressSearchResult?, String?) {
        return await getAddressFromLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
    }
    
    func getAddressFromLocation(_ location: CLLocation) async -> (AddressSearchResult?, String?) {
        isReverseGeocoding = true
        defer { isReverseGeocoding = false }
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            guard let placemark = placemarks.first else {
                return (nil, nil)
            }
            
            let formattedAddress = LocationManager.formatAddress(from: placemark)
            
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
            
        } catch {
            errorMessage = "Reverse geocoding failed: \(error.localizedDescription)"
            return (nil, nil)
        }
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
    
    func getCurrentLocationAddress() async -> (AddressSearchResult?, String?) {
        guard let location = location else { return (nil, nil) }
        return await getAddressFromLocation(location)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let newLocation = locations.last else { return }
            self.location = newLocation
            self.errorMessage = nil
            
            // Automatically get address for new location
            //_ = await self.getAddressFromLocation(newLocation) // Not needed
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    self.errorMessage = "Unable to determine location"
                case .denied:
                    self.errorMessage = "Location access denied"
                case .network:
                    self.errorMessage = "Network error while getting location"
                default:
                    self.errorMessage = "Location error: \(error.localizedDescription)"
                }
            } else {
                self.errorMessage = "Failed to get location: \(error.localizedDescription)"
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startLocationUpdates()
            case .denied, .restricted:
                self.errorMessage = "Location access denied"
                self.stopLocationUpdates()
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}
