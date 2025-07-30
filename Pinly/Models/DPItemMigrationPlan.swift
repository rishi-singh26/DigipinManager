//
//  DPItemMigrationPlan.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftData

enum DPItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [DPItemSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}
