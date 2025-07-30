//
//  DPItem.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import Foundation
import SwiftData

enum DPItemSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [DPItem.self]
    }
    
    @Model
    class DPItem: Identifiable, Codable {
        var id: String
        var name: String
        var pin: String
        var latitude: Double
        var longitude: Double
        var favourite: Bool
        var deleted: Bool
        var createdAt: Date
        var updatedAt: Date
            
        init(
            id: String = UUID().uuidString,
            name: String = "",
            pin: String,
            latitude: Double,
            longitude: Double,
            favourite: Bool = false,
            deleted: Bool = false,
            createdAt: Date = Date.now,
            updatedAt: Date = Date.now,
        ) {
            self.id = id
            self.name = name
            self.pin = pin
            self.latitude = latitude
            self.longitude = longitude
            self.deleted = deleted
            self.favourite = favourite
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
        
        // Codable implementation
        enum CodingKeys: String, CodingKey {
            case id, name, pin, latitude, longitude, deleted, favourite, createdAt, updatedAt
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(String.self, forKey: .id)
            
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
            pin = try container.decode(String.self, forKey: .pin)
            latitude = try container.decode(Double.self, forKey: .latitude)
            longitude = try container.decode(Double.self, forKey: .longitude)
            deleted = try container.decode(Bool.self, forKey: .deleted)
            favourite = try container.decode(Bool.self, forKey: .favourite)
            
            // Handle Date - parse from string if needed
            if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
               let date = createdAtString.toDate() {
                createdAt = date
            } else {
                createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date.now
            }
            
            if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt),
               let date = updatedAtString.toDate() {
                updatedAt = date
            } else {
                updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date.now
            }
        }
            
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(pin, forKey: .pin)
            try container.encode(latitude, forKey: .latitude)
            try container.encode(longitude, forKey: .longitude)
            try container.encode(deleted, forKey: .deleted)
            try container.encode(favourite, forKey: .favourite)
            
            // Format dates as ISO8601 strings
            let dateFormatter = ISO8601DateFormatter()
            try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        }
    }
}

typealias DPItem = DPItemSchemaV1.DPItem
