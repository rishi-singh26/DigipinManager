//
//  ImportView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 12/08/25.
//

import SwiftUI
import SwiftData

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationManager: InAppNotificationManager
    @State private var viewModel = ImportViewModel()
    
    @Query(filter: #Predicate<DPItem> { !$0.deleted }, sort: [SortDescriptor(\DPItem.createdAt, order: .reverse)])
    private var dpItems: [DPItem]
    
    var body: some View {
        List(viewModel.getV1DpItems, id: \.self, selection: $viewModel.selectedV1DPItems) { dpItem in
            VStack(alignment: .leading) {
                Text(dpItem.digipin)
                Text(dpItem.address)
                    .font(.caption.bold())
                if let safeErrMess = viewModel.errorDict[dpItem.digipin] {
                    Text(safeErrMess)
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .overlay {
            if viewModel.importDataVersion == nil {
                Button(action: {
                    viewModel.pickFileForImport()
                }) {
                    Text("Choose File")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 15)
                        .background(Color.accentColor, in: .capsule)
                }
                .buttonStyle(.plain)
            } else if let data = viewModel.v1ImportData, data.dpItems.isEmpty {
                Text("No DIGIPINs to import in the selected file")
            }
        }
        .toolbar {
            Button("Choose File") {
                viewModel.pickFileForImport()
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Unselect All") {
                    viewModel.unSelectAllDPItems()
                }
                Button("Select All") {
                    viewModel.selectAllDPItems(dpItems: dpItems)
                }
                Spacer()
                Button("Import") {
                    Task {
                        await importDPItems { errorDictionary in
                            viewModel.errorDict = errorDictionary
                        }
                    }
                }
                .disabled(viewModel.isImportButtonDisabled)
            }
        })
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $viewModel.isPickingFile,
            allowedContentTypes: [.plainText, .json],
            allowsMultipleSelection: false,
            onCompletion: viewModel.importData
        )
        .onChange(of: viewModel.errorMessage) { _, newValue in
            if !newValue.isEmpty {
                notificationManager.showToast(title: newValue, type: .error)
            }
        }
        .onChange(of: viewModel.selectedV1DPItems, handleSelectionChange)
    }
    
    private func importDPItems(completion: @escaping ([String: String]) -> Void) async {
        var errorMap: [String: String] = [:]
        
        guard let importVersion = viewModel.importDataVersion else {
            notificationManager.showToast(title: "Something went wrong! Import data not available", type: .error)
            return
        }
        
        switch importVersion {
        case ExportVersion.v1:
            for item in viewModel.selectedV1DPItems {
                let alreadyPresentIndex = dpItems.firstIndex(where: { $0.id == item.digipin })
                
                guard alreadyPresentIndex == nil else {
                    errorMap[item.digipin] = "Already present in pinned list"
                    continue
                }
                
                guard let lat = Double(item.latitude) else {
                    errorMap[item.digipin] = "Invalid latitude data"
                    continue
                }
                
                guard let lon = Double(item.longitude) else {
                    errorMap[item.digipin] = "Invalid longitude data"
                    continue
                }
                
                let formatter = ISO8601DateFormatter()
                guard let date = formatter.date(from: item.createdAt) else {
                    errorMap[item.digipin] = "Invalid date"
                    continue
                }
                
                modelContext.insert(DPItem(
                    pin: item.digipin,
                    note: item.note,
                    address: item.address,
                    latitude: lat,
                    longitude: lon,
                    favourite: item.favourite == "Yes",
                    createdAt: date
                ))
            }
        case ExportVersion.v2:
            notificationManager.showToast(title: "Unsupported version", type: .error)
            break
        }
        
        try? modelContext.save()
        notificationManager.showToast(title: "Import successfull", type: .success)
    }
    
    private func handleSelectionChange(old: Set<ExportV1DPItem>, newSelection: Set<ExportV1DPItem>) {
        dpItems.forEach { existingDPItem in
            if let item = newSelection.first(where: { $0.digipin == existingDPItem.id }) {
                viewModel.errorDict[item.digipin] = "Already present in pinned list"
                viewModel.selectedV1DPItems.remove(item)
            }
        }
    }
}

#Preview {
    ImportView()
}
