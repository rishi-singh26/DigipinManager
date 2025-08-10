//
//  DPItemMigrationPlan.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftData

enum DPItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [DPItemSchemaV1.self, DPItemSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: DPItemSchemaV1.self,
        toVersion: DPItemSchemaV2.self
    )
}
