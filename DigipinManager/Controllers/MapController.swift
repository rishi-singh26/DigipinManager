//
//  MapController.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import MapKit
import SwiftData

class MapController: ObservableObject {
    static let shared = MapController()
    
    private let digipinService = DIGIPIN()
    
    // Map Properties
    /// Current map center position
    @Published var position: MapCameraPosition =
        .region(MKCoordinateRegion(center: .init(latitude: 13.005677, longitude: 77.750530), latitudinalMeters: 1000, longitudinalMeters: 1000))
    
    @Published var selectedMapStyleType: MapStyleType = .standard
    @Published var showMapStyleSheet: Bool = false
    
    @Published var mapCenter: CLLocationCoordinate2D? { didSet { updatePin() } }
    /// pin for mapCenter, when map camera moves, the min for the map center is updated here
    @Published var digipin: String?
    /// AddressSearchResult data for map center
    @Published var addressData: (AddressSearchResult?, String?)
    /// When searching for a DIGIPIN, on successful search the coordinates are saved to this
    @Published var searchLocation: CLLocationCoordinate2D?
    /// AddressSearchResult data for searched DIFIPIN
    @Published var searchAddressData: (AddressSearchResult?, String?)
    
    func updatePin() {
        guard let center = mapCenter else { return }
        withAnimation(.bouncy) {
            digipin = getPinFrom(center: center)
        }
    }
}

// MARK: - Digipin methods
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

// MARK: - SwiftData Methods
extension MapController {
    func saveToPinnedList(pin: String, address: String, _ context: ModelContext) {
        guard let coords = self.getCoordinates(from: pin) else { return }
        let newDPItem = DPItem(pin: pin, address: address, latitude: coords.latitude, longitude: coords.longitude)
        context.insert(newDPItem)
        
        try? context.save()
    }
    
    func saveToPinnedListIfNotExist(_ pin: String, address: String, _ context: ModelContext) {
        guard let coords = self.getCoordinates(from: pin) else { return }
        
        let newDPItem = DPItem(pin: pin, address: address, latitude: coords.latitude, longitude: coords.longitude)
        
        let predicate = #Predicate<DPItem> { model in
            model.id == newDPItem.id
        }
        
        let descriptor = FetchDescriptor<DPItem>(predicate: predicate)
        
        do {
            let existingModels = try context.fetch(descriptor)
            
            if existingModels.isEmpty {
                context.insert(newDPItem)
                try context.save()
            } else {
                print("Model already exists")
            }
        } catch {
            print("Error checking for existing model: \(error)")
        }
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

enum MapStyleType: Equatable {
    case standard
    case imagery
    
    var mapStyle: MapStyle {
        switch self {
        case .standard:
            return MapStyle.standard
        case .imagery:
            return MapStyle.imagery(elevation: .realistic)
        }
    }
}
