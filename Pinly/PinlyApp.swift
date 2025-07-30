//
//  PinlyApp.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import SwiftData

@main
struct PinlyApp: App {
    var sharedModelContainer: ModelContainer
    
    @StateObject private var mapController = MapController()
    @StateObject private var mapViewModel = MapViewModel()
    
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
                .environmentObject(mapController)
                .environmentObject(mapViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
