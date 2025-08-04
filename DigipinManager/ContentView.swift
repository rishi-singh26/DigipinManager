//
//  ContentView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var mapController: MapController
    @EnvironmentObject private var notificationManager:  InAppNotificationManager
    
    @State private var hasUpdatedMap = true
    
    var body: some View {
        ZStack(alignment: .top) {
            MapView()
                .onAppear {
                    locationManager.requestLocationPermission()
                }
                .onReceive(locationManager.$location) { location in
                    if let location = location, !hasUpdatedMap {
                        mapController.updatedMapPosition(with: location.coordinate)
                    } else if hasUpdatedMap {
                        locationManager.stopLocationUpdates()
                    }
                }
        }
        .onChange(of: locationManager.errorMessage, { _, newValue in
            if !newValue.isEmpty {
                notificationManager.showNotification(title: "Error!", message: newValue, type: .neutral)
            }
        })
        .onAppear {
            Task(operation: appController.prfomrOnbordingCheck)
        }
        .withInAppNotifications()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DPItem.self, inMemory: true)
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(AppController.shared)
}
