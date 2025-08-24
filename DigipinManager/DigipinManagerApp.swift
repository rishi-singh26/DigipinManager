//
//  DigipinManagerApp.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct DigipinManagerApp: App {
    var sharedModelContainer: ModelContainer
    
    @StateObject private var appController = AppController()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    init() {
        self.sharedModelContainer = ModelContextContainer.shared.sharedModelContainer
        
        do {
            try Tips.configure()
        }
        catch {
            // Handle TipKit errors
            print("Error initializing TipKit \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.isNetworkConnected, networkMonitor.isConnected)
                .environment(\.connectionType, networkMonitor.connectionType)
                .environmentObject(appController)
                .environmentObject(MapController.shared)
                .environmentObject(MapViewModel.shared)
                .environmentObject(locationManager)
                .environmentObject(InAppNotificationManager.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
