//
//  ImportUtility.swift
//  DigipinManager
//
//  Created by Rishi Singh on 11/08/25.
//

import Foundation

class ImportUtility {
    static func decodeDataForImport(from importContent: String, type: ExportTypes) -> (ExportDataVersionOne?, String) {
        guard let data = importContent.data(using: .utf8) else {
            return (nil, "Conversion to Data failed")
        }
        
        switch type {
        case ExportTypes.CSV:
            let (decoded, message) = ImportUtility.decodeCSV(from: data)
            return (decoded, message)
        case ExportTypes.JSON:
            let (decoded, message) = ImportUtility.decodeJSON(from: data)
            return (decoded, message)
        }
    }
    
    static func decodeJSON(from data: Data) -> (ExportDataVersionOne?, String) {
        do {
            // Decode version only
            let versionContainer = try JSONDecoder().decode(VersionContainer.self, from: data)
            
            switch versionContainer.version {
            case ExportVersion.v1:
                let (decoded, message) = ImportUtility.decodeVersionOneJSONData(from: data)
                return (decoded, message)
            case ExportVersion.v2:
                return (nil, "Unsupported version: \(versionContainer.version)")
            }
        } catch {
            return (nil, "Failed to decode version info: \(error)")
        }
    }
    
    static func decodeVersionOneJSONData(from data: Data) -> (ExportDataVersionOne?, String) {
        do {
            let decodedData = try JSONDecoder().decode(ExportDataVersionOne.self, from: data)
            return (decodedData, "Success")
        } catch {
            return (nil, "Decoding failed: \(error)")
        }
    }
    
    static func decodeCSV(from data: Data) -> (ExportDataVersionOne?, String) {
        guard let csvString = String(data: data, encoding: .utf8) else {
            return (nil, "Decoding data from CSV failed")
        }
        
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // Make sure there are at least 2 lines (header + 1 data row)
        guard lines.count >= 2 else { return (nil, "Not enough data, first row is ignored as the header row") }
        
        let dataRows = Array(lines.dropFirst()) // Drop the header row
        let cleanLastRow = decodeCSVRow(row: dataRows.last!)
        guard let version = cleanLastRow.last, let exportVersion = ExportVersion(rawValue: String(version)) else {
            return (nil , "Could not figure out version information")
        }
        
        switch exportVersion {
        case ExportVersion.v1:
            if let importableData = ExportDataVersionOne.fromCSV(dataRows) {
                return (importableData, "Success")
            } else {
                return (nil, "Decoding data from CSV failed")
            }
        case ExportVersion.v2:
            return (nil, "Unsupported version")
        }
    }
    
    static func decodeCSVRow(row: String) -> [String] {
        let pattern = #"""
                    "(?:[^"]|"")*"|[^,]+
                    """#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        let nsRow = row as NSString
        let matches = regex?.matches(in: row, range: NSRange(location: 0, length: nsRow.length)) ?? []
        
        let fields = matches.map {
            var field = nsRow.substring(with: $0.range)
            // Remove surrounding quotes if present
            if field.hasPrefix("\""), field.hasSuffix("\"") {
                field.removeFirst()
                field.removeLast()
                // Unescape double quotes
                field = field.replacingOccurrences(of: "\"\"", with: "\"")
            }
            return field
        }
        
        return fields
    }
}
