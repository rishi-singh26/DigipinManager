//
//  LocationManager.swift
//  DigipinManager
//
//  Created by Rishi Singh on 31/07/25.
//

import SwiftUI
import MapKit

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
    @Published var errorMessage: String = ""
    
    var hasLocationPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var canAskForPermission: Bool {
        authorizationStatus == .notDetermined
    }
    
    private let locationManager = CLLocationManager()
    
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
        guard canAskForPermission else { return }
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            updateError(with: "Location access denied. Please enable location access in Settings.")
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            updateError(with: "Location permission not granted")
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Error handling
    func updateError(with message: String) {
        withAnimation {
            errorMessage = message
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let newLocation = locations.last else { return }
            self.location = newLocation
            updateError(with: "")
            
            // Automatically get address for new location
            //_ = await self.getAddressFromLocation(newLocation) // Not needed
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    updateError(with: "Unable to determine location")
                case .denied:
                    updateError(with: "Location access denied. Please enable location access in Settings.")
                case .network:
                    updateError(with: "Network error while getting location")
                default:
                    updateError(with: "Location error: \(error.localizedDescription)")
                }
            } else {
                updateError(with: "Failed to get location: \(error.localizedDescription)")
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
                updateError(with: "Location access denied. Please enable location access in Settings.")
                self.stopLocationUpdates()
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}
