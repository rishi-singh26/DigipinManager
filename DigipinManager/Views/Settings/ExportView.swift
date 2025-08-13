//
//  ExportView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 11/08/25.
//

import SwiftUI
import SwiftData

struct ExportView: View {
    @State private var viewModel = ExportViewModel()
    @EnvironmentObject private var notificationManager: InAppNotificationManager
    
    @Query(filter: #Predicate<DPItem> { !$0.deleted }, sort: [SortDescriptor(\DPItem.createdAt, order: .reverse)])
    private var dpItems: [DPItem]
    
    var body: some View {
        List(dpItems, id: \.self, selection: $viewModel.selectedExportDPitems) { dpItem in
            VStack(alignment: .leading) {
                HStack {
                    Text(dpItem.id)
                    
                    Spacer()
                    
                    if let note = dpItem.note {
                        Text(note)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(width: 150, alignment: .trailing)
                    }
                }
                Text(dpItem.address)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .environment(\.editMode, .constant(.active))
        .toolbar {
            Button {
                viewModel.showExportTypePicker = true
            } label: {
                Text(viewModel.selectedExportType.displayName)
                    .contentTransition(.numericText())
                    .frame(minWidth: 80, alignment: .trailing)
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Unselect All") {
                    viewModel.selectedExportDPitems = []
                }
                Button("Select All") {
                    viewModel.selectedExportDPitems = Set(dpItems)
                }
                Spacer()
                Button("Export") {
                    viewModel.exportDigipinItems()
                }
                .disabled(viewModel.selectedExportDPitems.isEmpty)
            }
        })
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .systemTrayView($viewModel.showExportTypePicker) {
            ExportTypePicker()
        }
        .fileExporter(
            isPresented: $viewModel.isExportingFile,
            document: try? MultiFormatDocument(
                object: viewModel.exportData,
                type: viewModel.exportContentType
            ),
            contentType: viewModel.exportContentType,
            defaultFilename: viewModel.exportFileName,
            onCompletion: viewModel.handleExportCompletion
        )
        .onChange(of: viewModel.errorMessage) { _, newValue in
            if !newValue.isEmpty {
                notificationManager.showToast(title: newValue, type: viewModel.notificationType)
            }
        }
    }
    
    @ViewBuilder
    private func ExportTypePicker() -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                HStack {
                    Text("Choose Export Type")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer(minLength: 0)
                    
                    Button {
                        viewModel.showExportTypePicker = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                    }
                }
                .padding(.bottom, 25)
                
                VStack(alignment: .leading) {
                    Text(viewModel.selectedExportType.description)
                        .multilineTextAlignment(.leading)
                        .transition(.slide)
                        .padding(20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 25))
                .padding(.bottom, 25)
                
                ForEach(ExportTypes.allCases) { exportType in
                    let isSelected: Bool = exportType == viewModel.selectedExportType
                    
                    HStack(spacing: 10) {
//                        Label(exportType.displayName, systemImage: exportType.symbol)
                        Image(systemName: exportType.symbol)
                            .frame(width: 40)
                        
                        Text(exportType.displayName)
                        
                        Spacer()
                        
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle.fill")
                            .font(.title3)
                            .contentTransition(.symbolEffect)
                            .foregroundStyle(isSelected ? .accentColor : Color.gray.opacity(0.2))
                    }
                    .padding(.vertical, 6)
                    .contentShape(.rect)
                    .onTapGesture {
                        if !isSelected {
                            withAnimation(.bouncy) {
                                viewModel.selectedExportType = exportType
                            }
                        }
                    }
                }
            }
            
            // Continue button
            Button {
                viewModel.showExportTypePicker = false
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: .capsule)
            }
            .padding(.top, 15)
        }
        .padding(20)
    }
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let container = try! ModelContainer(for: DPItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        // Add sample data
        let sampleDPItems = [
            DPItem(pin: "4P3-33C-4635", address: "Address Data", latitude: 13.006003, longitude: 77.751144),
            DPItem(pin: "4P3-33C-5MMJ", address: "Address Data", latitude: 13.005222, longitude: 77.752166),
            DPItem(pin: "4P3-33C-P7JF", address: "Address Data", latitude: 13.004407, longitude: 77.753131),
            DPItem(pin: "4P3-33C-T9MF", address: "Address Data", latitude: 13.004709, longitude: 77.754909)
        ]
        
        for item in sampleDPItems {
            container.mainContext.insert(item)
        }
        
        return container
    }()
    
    SettingsView()
        .modelContainer(container)
}
