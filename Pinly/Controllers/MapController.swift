//
//  MapController.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import MapKit

class MapController: ObservableObject {
    static let shared = MapController()
    
    private let digipinService = DIGIPIN()
    
    // Map Properties
    /// Current map center position
    @Published var position: MapCameraPosition =
        .region(MKCoordinateRegion(center: .init(latitude: 13.005677, longitude: 77.750530), latitudinalMeters: 1000, longitudinalMeters: 1000))
    @Published var selectedMapStyle: MapStyle = .standard
    
    @Published var mapCenter: CLLocationCoordinate2D? { didSet { updatePin() } }
    // pin for mapCenter, when map camera moves, the min for the map center is updated here
    @Published var digipin: String?
    // address data for map center
    @Published var addressData: (AddressSearchResult?, String?)
    // When searching for a DIGIPIN, on successful search the coordinates are saved to this
    @Published var searchLocation: CLLocationCoordinate2D?
    // address data for searched DIFIPIN
    @Published var searchAddressData: (AddressSearchResult?, String?)
    
    func updatePin() {
        guard let center = mapCenter else { return }
        withAnimation(.bouncy) {
            digipin = getPinFrom(center: center)
        }
    }
}

// MARK: - Digipin methids
extension MapController {
    func getPinFrom(center: CLLocationCoordinate2D) -> String? {
        return getPinFrom(coords: Coordinate(latitude: center.latitude, longitude: center.longitude))
    }
    
    func getPinFrom(coords: Coordinate) -> String? {
        return try? digipinService.generateDIGIPIN(latitude: coords.latitude, longitude: coords.longitude)
    }
    
    func updatedMapPosition(with pin: String) {
        guard let coords = getCoordinates(from: pin) else { return }
        updatedMapPosition(with: coords)
    }
    
    func updatedMapPosition(with coordinate: CLLocationCoordinate2D) {
        updatedMapPosition(with: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
    
    func updatedMapPosition(with coords: Coordinate) {
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: .init(latitude: coords.latitude, longitude: coords.longitude),
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
        }
    }
    
    func updatedMapPositionAndSearchLocation(with coords: Coordinate) {
        searchLocation = .init(latitude: coords.latitude, longitude: coords.longitude)
        withAnimation(.interpolatingSpring(duration: 0.5, bounce: 0, initialVelocity: 0)) {
            position = .region(MKCoordinateRegion(
                center: .init(latitude: coords.latitude, longitude: coords.longitude),
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
        }
    }
    
    func getCoordinates(from pin : String) -> Coordinate? {
        return try? digipinService.coordinate(from: pin)
    }
}

extension MapController {
    static let boundPoints: [MKMapPoint] = [
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 2.5,
            longitude: 63.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 2.5,
            longitude: 99.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 38.5,
            longitude: 99.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 38.5,
            longitude: 63.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 2.5,
            longitude: 63.5
        ))
    ]
}
