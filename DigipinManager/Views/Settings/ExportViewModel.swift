//
//  ExportViewModel.swift
//  DigipinManager
//
//  Created by Rishi Singh on 11/08/25.
//

import SwiftUI
import UniformTypeIdentifiers

@Observable
class ExportViewModel {
    // MARK: - Import Page properties
    var isPickingFile: Bool = false
    /// Data captured from import file
    var v1ImportData: ExportDataVersionOne? = nil
    /// Selected V1 addresses for import/
    var selectedV1Addresses: Set<ExportV1DPItem> = []
    /// Version of the import data, application logic will deped on this
    var importDataVersion: String? = nil
    
    var selectedExportDPitems: Set<DPItem> = []
    var selectedExportType: ExportTypes = .CSV
    var showExportTypePicker: Bool = false
    
    var exportData: ExportDataVersionOne = ExportDataVersionOne(dpItems: [])
    var isExportingFile: Bool = false
    
    func exportDigipinItems() {
        if selectedExportDPitems.isEmpty {
            showAlert(with: "Please select digipins to export.")
            return
        }
        
        exportData = ExportDataVersionOne(dpItems: Array(selectedExportDPitems).map({
            ExportV1DPItem(dpItem: $0)
        }))
        isExportingFile = true
        selectedExportDPitems = []
    }
    
    func handleExportCompletion(_ result: Result<URL, any Error>) -> Void {
        var message = ""
        switch result {
        case .success:
            message = "Exported successfully"
        case .failure:
            message = "Export failed"
        }
        showAlert(with: message)
    }
    
    // MARK: - Error handelling properties
    var errorMessage: String = ""
    var showErrorAlert: Bool = false
    
    func showAlert(with message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    var exportContentType: UTType {
        switch selectedExportType {
        case .JSON:
            return .json
        case .CSV:
            return .commaSeparatedText
        }
    }
    
    var exportFileName: String {
        let ext = (selectedExportType == .JSON) ? "json" : "csv"
        return "DigipinManagerExport-\(Date.now.dd_mmm_yyyy()).\(ext)"
    }
}


// MARK: - Export Types
enum ExportTypes: String, CaseIterable, Identifiable {
    case CSV = "CSV"
    case JSON = "JSON"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .CSV: return "CSV"
        case .JSON: return "JSON"
        }
    }
    
    var description: String {
        switch self {
        case .CSV:
            return "DIGIPINs will be exported to a CSV file. The exported file will have following data for each DIGIPIN\n- DIGIPIN\n- Address\n- Latitude\n- Longitude\n- Note\n- Favourite\n- Created At"
        case .JSON:
            return "DIGIPINs will be exported to a JSON file. This is less readable then a CSV file. The exported file will have following data for each DIGIPIN\n- DIGIPIN\n- Address\n- Latitude\n- Longitude\n- Note\n- Favourite\n- Created At"
        }
    }
    
    var symbol: String {
        switch self {
        case .CSV: return "table"
        case .JSON: return "ellipsis.curlybraces"
        }
    }
}
