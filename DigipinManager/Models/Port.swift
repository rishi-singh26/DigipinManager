//
//  Port.swift
//  DigipinManager
//
//  Created by Rishi Singh on 11/08/25.
//

import Foundation
import UniformTypeIdentifiers

enum PortError: Error {
    case objectToDataConversionFailed
    case encodingFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .objectToDataConversionFailed:
            return "Failed to convert export object to data."
        case .encodingFailed(let underlying):
            return "Failed to encode object to JSON. Reason: \(underlying.localizedDescription)"
        }
    }
}

enum ExportVersion: String {
    case v1 = "1.0.0"
    case v2 = "2.0.0"
}

struct VersionContainer: Codable {
    let version: String
    let exportDate: String
}

protocol Portable: FileEncodable, Codable {
    var version: String { get }
    var exportDate: String { get }
}

// MARK: - Export Data Version One models
struct ExportDataVersionOne: Portable {
    let version: String = ExportVersion.v1.rawValue
    let exportDate: String
    let dpItems: [ExportV1DPItem]
    
    init(dpItems: [ExportV1DPItem]) {
        self.dpItems = dpItems
        self.exportDate = Date.now.ISO8601Format()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedVersion = try container.decode(String.self, forKey: .version)
        guard decodedVersion == version else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: container,
                debugDescription: "Unsupported version: \(decodedVersion). Expected version: \(version)."
            )
        }
        exportDate = try container.decode(String.self, forKey: .exportDate)
        dpItems = try container.decode([ExportV1DPItem].self, forKey: .dpItems)
    }

    /// Encodes the object to JSON string
    func toJSON(prettyPrinted: Bool = true) throws -> String {
        let data: Data = try self.toJSON(prettyPrinted: prettyPrinted)
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(self, .init(
                codingPath: [],
                debugDescription: "Failed to convert data to UTF-8 string."
            ))
        }
        return jsonString
    }
    
    /// Encodes the object to JSON data
    func toJSON(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        do {
            return try encoder.encode(self)
        } catch {
            throw PortError.objectToDataConversionFailed
        }
    }
    
    func toCSV() -> String {
        // CSV Header
        var csv = "DIGIPIN,Address,Latitude,Longitude,Note,Favourite,Created At\n"

        // CSV Rows
        for dpItem in dpItems {
            csv.append(dpItem.toCSVRow() + "\n")
        }
        return csv
    }
    
    func toCSV() -> Data {
        let csv: String = self.toCSV()
        return csv.data(using: .utf8) ?? Data()
    }
    
    func encodeData(for type: UTType) throws -> Data {
        switch type {
        case .json:
            try self.toJSON()
        case .commaSeparatedText:
            self.toCSV()
        default:
            Data()
        }
    }
}

struct ExportV1DPItem: Codable, Hashable {
    let digipin: String
    let note: String
    let address: String
    let latitude: String
    let longitude: String
    let favourite: String
    let createdAt: String
    
    init(digipin: String, note: String, address: String, latitude: String, longitude: String, favourite: String, createdAt: String) {
        self.digipin = digipin
        self.note = note
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.favourite = favourite
        self.createdAt = createdAt
    }
    
    init(dpItem: DPItem) {
        self.digipin = dpItem.id
        self.note = dpItem.note ?? ""
        self.address = dpItem.address
        self.latitude = String(format: "%.7f", dpItem.longitude)
        self.longitude = String(format: "%.7f", dpItem.longitude)
        self.favourite = dpItem.favourite ? "Yes" : "No"
        self.createdAt = dpItem.createdAt.ISO8601Format()
    }
    
    func toCSVRow() -> String {
        [digipin, address, latitude, longitude, note, favourite, createdAt]
            .map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" } // escape quotes
            .joined(separator: ",")
    }
}
