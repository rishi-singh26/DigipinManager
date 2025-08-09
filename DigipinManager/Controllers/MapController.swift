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
    @Published var position: MapCameraPosition = .automatic
    
    @Published var selectedMapStyleType: MapStyleType = .standard
    @Published var showMapStyleSheet: Bool = false
    
    @Published var mapCenter: CLLocationCoordinate2D? { didSet { updatePinAndAddress() } }
    /// pin for mapCenter, when map camera moves, the min for the map center is updated here
    @Published var digipin: String?
    /// AddressSearchResult data for map center
    @Published var addressData: (AddressSearchResult?, String?)
    /// When searching for a DIGIPIN, on successful search the coordinates are saved to this
    @Published private(set) var searchLocation: CLLocationCoordinate2D?
    /// AddressSearchResult data for searched DIFIPIN
    @Published var searchAddressData: (AddressSearchResult?, String?)
    
    func updatePinAndAddress() {
        guard let center = mapCenter else { return }
        let newDigipin = getPinFrom(center: center)
        
        withAnimation(.bouncy) {
            digipin = newDigipin
        }
        
        guard newDigipin != nil else { return } // Do not updated address if DIGIPIN is not available
        
        Task {
            guard let result = try? await AddressUtility.shared.getAddressFromLocation(center) else { return }
            await MainActor.run {
                withAnimation {
                    addressData = result
                }
            }
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
                span: position.region?.span ?? MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }
    
    func updatedMapPositionAndSearchLocation(with coords: Coordinate) {
        updateSearchLocation(with: .init(latitude: coords.latitude, longitude: coords.longitude))
        updatedMapPosition(with: coords)
    }
    
    func getCoordinates(from pin : String) -> Coordinate? {
        return try? digipinService.coordinate(from: pin)
    }
    
    func closeSearch() {
        withAnimation {
            searchLocation = nil
            searchAddressData = (nil, nil)
        }
    }
    
    func updateSearchLocation(with location: CLLocationCoordinate2D?) {
        withAnimation {
            searchLocation = location
        }
    }
}

// MARK: - SwiftData Methods
extension MapController {
    func saveToPinnedList(pin: String, address: String, _ context: ModelContext) -> Bool {
        guard let coords = self.getCoordinates(from: pin) else { return false }
        let newDPItem = DPItem(pin: pin, address: address, latitude: coords.latitude, longitude: coords.longitude)
        context.insert(newDPItem)
        
        return (try? context.save()) != nil
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
            latitude: 38.5,
            longitude: 63.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 38.5,
            longitude: 99.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 2.5,
            longitude: 99.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 2.5,
            longitude: 63.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 38.5,
            longitude: 63.5
        )),
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
