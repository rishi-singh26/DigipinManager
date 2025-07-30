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
    // Map Properties
    @Published var currentPosition: MapCameraPosition =
        .region(MKCoordinateRegion(center: .init(latitude: 37.3346, longitude: -122.0090), latitudinalMeters: 1000, longitudinalMeters: 1000))
    @Published var selectedMapStyle: MapStyle = .standard
    
    var mapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
}
