//
//  ImportViewModel.swift
//  DigipinManager
//
//  Created by Rishi Singh on 12/08/25.
//

import Foundation

@Observable
class ImportViewModel {
    // MARK: - Import Page properties
    var isPickingFile: Bool = false
    /// Data captured from import file
    var v1ImportData: ExportDataVersionOne? = nil
    /// Selected V1 DPitems for import/
    var selectedV1DPItems: Set<ExportV1DPItem> = []
    /// Dictonary of errors after import attempt [messageId: errorMessage]
    var errorDict: [String: String] = [:]
    /// Version of the import data, application logic will deped on this
    var importDataVersion: ExportVersion? = nil
    var isImportButtonDisabled: Bool {
        selectedV1DPItems.isEmpty
    }
    
    /// DPItems in the selected import, the dpitems already in swift data are filtered out
    var getV1DpItems: [ExportV1DPItem] {
        return (v1ImportData?.dpItems ?? [])
    }
    
    func selectAllDPItems(dpItems: [DPItem]) {
        if importDataVersion == ExportVersion.v1 {
            selectedV1DPItems = Set(
                (v1ImportData?.dpItems ?? []).filter { dpItem in
                    let idMatches = dpItems.first(where: { existingDPitem in
                        dpItem.digipin == existingDPitem.id && !existingDPitem.deleted
                    })
                    if idMatches != nil {
                        errorDict[dpItem.digipin] = "Already present in pinned list"
                    }
                    return idMatches == nil
                }
            )
        }
    }
    
    func unSelectAllDPItems() {
        if importDataVersion == ExportVersion.v1 {
            selectedV1DPItems = []
        }
    }
    
    // MARK: - Error handelling properties
    var errorMessage: String = ""
    var showErrorAlert: Bool = false
    
    func showAlert(with message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    
    // MARK: - Import data handlers
    func pickFileForImport() {
        isPickingFile = true
    }

    func importData(from result: Result<[URL], any Error>) {
        let (_, content, statusMessage, fileExtension) = FileUtility.getFileContentFromFileImporterResult(result)
        
        guard let content else {
            showAlert(with: statusMessage)
            return
        }
        
        guard let type = ExportTypes(rawValue: fileExtension.uppercased()) else {
            showAlert(with: "Invalid file extension")
            return
        }

        let (v1Data, message) = ImportUtility.decodeDataForImport(from: content, type: type)
        
        self.v1ImportData = v1Data
        selectedV1DPItems = []

        if v1Data == nil {
            showAlert(with: message)
        }
        
        importDataVersion = v1Data?.version ?? nil
    }
}
