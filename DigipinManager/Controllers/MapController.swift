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
    
    // MARK: - Persistent Storage Keys via @AppStorage
    @AppStorage(StorageKeys.savedLatitude) private var savedLatitude: CLLocationDegrees = 20.5
    @AppStorage(StorageKeys.savedLongitude) private var savedLongitude: CLLocationDegrees = 81.5
    @AppStorage(StorageKeys.savedLatDelta) private var savedLatDelta: CLLocationDegrees = 40
    @AppStorage(StorageKeys.savedLonDelta) private var savedLonDelta: CLLocationDegrees = 40
    @AppStorage(StorageKeys.savedMapStyle) private var savedMapStyle: String = "Standard"
    
    // Map Properties
    /// Current map center position
    @Published var position: MapCameraPosition
    @Published var selectedMapStyleType: MapStyleType = .standard { didSet { saveSelectedMapStyle() }}
    @Published var showMapStyleSheet: Bool = false
    
    @Published private(set) var mapCenter: CLLocationCoordinate2D? { didSet { updatePinAndAddress() } }
    /// pin for mapCenter, when map camera moves, the min for the map center is updated here
    @Published private(set) var digipin: String?
    /// AddressSearchResult data for map center
    @Published private(set) var addressData: (AddressSearchResult?, String?)
    
    private init() {
        // Initialize position with default values first
        position = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.5, longitude: 81.5),
            span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
        ))
        
        // Now load saved data
        loadSavedData()
    }
    
    func updatePinAndAddress() {
        guard let center = mapCenter else { return }
        let newDigipin = try? DigipinUtility.getPinFrom(center: center)
        
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
    
    func updatedMapPosition(with pin: String) {
        guard let coords = DigipinUtility.getCoordinates(from: pin) else { return }
        updatedMapPosition(with: coords)
    }
    
    func updatedMapPosition(with coordinate: CLLocationCoordinate2D) {
        updatedMapPosition(with: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
    
    func updatedMapPosition(with coords: Coordinate) {
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: .init(latitude: coords.latitude, longitude: coords.longitude),
                span: position.region?.span ?? MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            ))
        }
    }
}

// MARK: - Storage logic
extension MapController {
    private enum StorageKeys {
        static let savedLatitude = "MapCenterLatitude"
        static let savedLongitude = "MapCenterLongitude"
        static let savedLatDelta = "MapSpanLatDelta"
        static let savedLonDelta = "MapSpanLonDelta"
        static let savedMapStyle = "SelectedMapStyle"
    }
    
    private func loadSavedData() {
        loadSavedPosition()
        loadSavedMapStyle()
    }
    
    private func savePosition(region: MKCoordinateRegion) {
        savedLatitude = region.center.latitude
        savedLongitude = region.center.longitude
        savedLatDelta = region.span.latitudeDelta
        savedLonDelta = region.span.longitudeDelta
    }
    
    private func loadSavedPosition() {
        let savedRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: savedLatitude, longitude: savedLongitude),
            span: MKCoordinateSpan(latitudeDelta: savedLatDelta, longitudeDelta: savedLonDelta)
        )
        position = .region(savedRegion)
    }
    
    private func saveSelectedMapStyle() {
        savedMapStyle = selectedMapStyleType == .standard ? "Standard" : "Imagery"
    }
    
    private func loadSavedMapStyle() {
        selectedMapStyleType = savedMapStyle == "Standard" ? .standard : .imagery
    }
}

// MARK: - Additional helper methods for better position management
extension MapController {
    /// Call this method when the map region changes to save the current position (debounced)
    func onMapRegionChanged(_ region: MKCoordinateRegion) {
        mapCenter = region.center
        self.savePosition(region: region)
    }
}

// MARK: - SwiftData Methods
extension MapController {
    func saveCurrentLocDigipin(_ modelContext: ModelContext) async -> (Bool, String?) {
        guard let currentPosition = mapCenter else { return (false, nil) }
        guard let pin = digipin else { return (false, nil) }

        let result = try? await AddressUtility.shared.getAddressFromLocation(currentPosition)
        guard let address = result?.1 else { return (false, nil) }

        return saveToPinnedListIfNotExist(pin: pin, address: address, modelContext)
    }

    
    func saveToPinnedList(pin: String, address: String, _ context: ModelContext) -> Bool {
        guard let coords = DigipinUtility.getCoordinates(from: pin) else { return false }
        let newDPItem = DPItem(pin: pin, address: address, latitude: coords.latitude, longitude: coords.longitude)
        context.insert(newDPItem)
        
        return (try? context.save()) != nil
    }
    
    func saveToPinnedListIfNotExist(pin: String, address: String, _ context: ModelContext) -> (Bool, String?) {
        guard let coords = DigipinUtility.getCoordinates(from: pin) else { return (false, nil) }
        return saveToPinnedListIfNotExist(pin: pin, address: address, coords: coords, context)
    }
    
    func saveToPinnedListIfNotExist(pin: String, address: String, coords: Coordinate,  _ context: ModelContext) -> (Bool, String?) {
        let newItem = DPItem(pin: pin, address: address, latitude: coords.latitude, longitude: coords.longitude)
        let predicate = #Predicate<DPItem> { $0.id == newItem.id }
        let descriptor = FetchDescriptor<DPItem>(predicate: predicate)

        do {
            if try context.fetch(descriptor).isEmpty {
                context.insert(newItem)
                try context.save()
                return (true, nil)
            } else {
                return (false, "Already added to pinned list")
            }
        } catch {
            // Handle error if needed
            return (false, nil)
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
