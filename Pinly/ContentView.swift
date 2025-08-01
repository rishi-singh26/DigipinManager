//
//  ContentView.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var mapController: MapController
    
    @State private var hasUpdatedMap = true
    
    var body: some View {
        MapView()
            .onAppear {
                locationManager.requestLocationPermission()
            }
            //Update map position on user location update
            .onReceive(locationManager.$location) { location in
                if let location = location, !hasUpdatedMap {
                    mapController.updatedMapPosition(with: location.coordinate)
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DPItem.self, inMemory: true)
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
}
