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

        // Parse the whole file at once (rather than splitting on newlines first) so that
        // newlines embedded inside a quoted field don't get mistaken for row boundaries.
        let rows = parseCSVRows(from: csvString)

        // Make sure there are at least 2 rows (header + 1 data row)
        guard rows.count >= 2 else { return (nil, "Not enough data, first row is ignored as the header row") }

        let dataRows = Array(rows.dropFirst()) // Drop the header row
        guard let lastRow = dataRows.last, let version = lastRow.last, let exportVersion = ExportVersion(rawValue: version) else {
            return (nil , "Could not figure out version information")
        }

        switch exportVersion {
        case ExportVersion.v1:
            let items = dataRows.compactMap { ExportV1DPItem.fromCSVFields($0) }
            return (ExportDataVersionOne(dpItems: items, type: .CSV), "Success")
        case ExportVersion.v2:
            return (nil, "Unsupported version")
        }
    }

    /// Splits a single CSV line into fields, honoring quoted fields (including embedded
    /// commas and escaped `""` quotes) and correctly preserving empty fields.
    static func decodeCSVRow(row: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        let chars = Array(row)
        var i = 0
        let n = chars.count

        while i < n {
            let c = chars[i]
            if insideQuotes {
                if c == "\"" {
                    if i + 1 < n && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                    } else {
                        insideQuotes = false
                        i += 1
                    }
                } else {
                    currentField.append(c)
                    i += 1
                }
            } else if c == "\"" {
                insideQuotes = true
                i += 1
            } else if c == "," {
                fields.append(currentField)
                currentField = ""
                i += 1
            } else {
                currentField.append(c)
                i += 1
            }
        }
        fields.append(currentField)

        return fields
    }

    /// Parses a full CSV document into rows of fields, honoring quoted fields that span
    /// multiple lines (a quoted field may contain a literal newline).
    static func parseCSVRows(from csvString: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        let chars = Array(csvString)
        var i = 0
        let n = chars.count

        func endField() {
            currentRow.append(currentField)
            currentField = ""
        }
        func endRow() {
            endField()
            rows.append(currentRow)
            currentRow = []
        }

        while i < n {
            let c = chars[i]
            if insideQuotes {
                if c == "\"" {
                    if i + 1 < n && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                    } else {
                        insideQuotes = false
                        i += 1
                    }
                } else {
                    currentField.append(c)
                    i += 1
                }
                continue
            }

            switch c {
            case "\"":
                insideQuotes = true
                i += 1
            case ",":
                endField()
                i += 1
            case "\r":
                if i + 1 < n && chars[i + 1] == "\n" {
                    i += 1
                }
                endRow()
                i += 1
            case "\n":
                endRow()
                i += 1
            default:
                currentField.append(c)
                i += 1
            }
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            endRow()
        }

        // Drop blank lines (e.g. a trailing newline at EOF produces one empty row).
        return rows.filter { !($0.count == 1 && $0[0].trimmingCharacters(in: .whitespaces).isEmpty) }
    }
}
