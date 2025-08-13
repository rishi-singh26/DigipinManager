//
//  ModelContainer.swift
//  DigipinManager
//
//  Created by Rishi Singh on 13/08/25.
//

import SwiftData

class ModelContextContainer {
    static let shared = ModelContextContainer()
    
    let sharedModelContainer: ModelContainer
    
    private init() {
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
    }
}
