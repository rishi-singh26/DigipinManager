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

enum ExportVersion: String, Codable {
    case v1 = "1.0.0"
    case v2 = "2.0.0"
}

struct VersionContainer: Codable {
    let version: ExportVersion
    let exportDate: String
    let exportType: ExportTypes
}

protocol Portable: FileEncodable, Codable {
    var version: ExportVersion { get }
    var exportDate: String { get }
}

// MARK: - Export Data Version One models
struct ExportDataVersionOne: Portable {
    let version: ExportVersion = ExportVersion.v1
    let exportDate: String
    let exportType: ExportTypes
    let dpItems: [ExportV1DPItem]
    
    init(dpItems: [ExportV1DPItem], type: ExportTypes) {
        self.dpItems = dpItems
        self.exportType = type
        self.exportDate = Date.now.ISO8601Format()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedVersion = try container.decode(ExportVersion.self, forKey: .version)
        guard decodedVersion == version else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: container,
                debugDescription: "Unsupported version: \(decodedVersion). Expected version: \(version)."
            )
        }
        exportDate = try container.decode(String.self, forKey: .exportDate)
        exportType = try container.decode(ExportTypes.self, forKey: .exportType)
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
        var csv = "DIGIPIN,Address,Latitude,Longitude,Note,Favourite,Created At,Version\n"
        
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
    
    /// Create `ExportDataVersionOne` from CSV Data
    static func fromCSV(_ data: Data) -> ExportDataVersionOne? {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        return fromCSV(string)
    }
    
    /// Create `ExportDataVersionOne` from CSV String (Unused)
    static func fromCSV(_ csv: String) -> ExportDataVersionOne? {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // Make sure there are at least 2 lines (header + 1 data row)
        guard lines.count >= 2 else { return nil }
        
        let dataRows = Array(lines.dropFirst())
        
        return fromCSV(dataRows)
    }
    
    /// Create `ExportDataVersionOne` from CSV lines array
    static func fromCSV(_ csvLines: [String]) -> ExportDataVersionOne? {
        var items: [ExportV1DPItem] = []
        
        for line in csvLines {
            if let item = ExportV1DPItem.fromCSVRow(line) {
                items.append(item)
            } else {
                continue
            }
        }
        
        return ExportDataVersionOne(dpItems: items, type: .CSV)
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
        [digipin, address, latitude, longitude, note, favourite, createdAt, ExportVersion.v1.rawValue]
            .map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" } // escape quotes
            .joined(separator: ",")
    }
    
    /// Creates an `ExportV1DPItem` from a single CSV row string
    static func fromCSVRow(_ csvRow: String) -> ExportV1DPItem? {
        let fields = ImportUtility.decodeCSVRow(row: csvRow)
        
        guard fields.count == 8 else {
            return nil
        }
        
        return ExportV1DPItem(
            digipin: fields[0],
            note: fields[4],
            address: fields[1],
            latitude: fields[2],
            longitude: fields[3],
            favourite: fields[5],
            createdAt: fields[6]
        )
    }
}
