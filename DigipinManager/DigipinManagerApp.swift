//
//  DigipinManagerApp.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import SwiftData

@main
struct DigipinManagerApp: App {
    var sharedModelContainer: ModelContainer
    
    @StateObject private var appController = AppController()
    @StateObject private var mapController = MapController.shared
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    init() {
        let container: ModelContainer
        do {
            let schema = Schema([
                DPItem.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, migrationPlan: DPItemMigrationPlan.self, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        self.sharedModelContainer = container
//        _addressesController = StateObject(wrappedValue: AddressesController(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.isNetworkConnected, networkMonitor.isConnected)
                .environment(\.connectionType, networkMonitor.connectionType)
                .environmentObject(appController)
                .environmentObject(mapController)
                .environmentObject(mapViewModel)
                .environmentObject(locationManager)
                .environmentObject(InAppNotificationManager.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
