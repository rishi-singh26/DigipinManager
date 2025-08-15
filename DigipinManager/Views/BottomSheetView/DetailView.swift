//
//  DetailView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 02/08/25.
//

import SwiftUI
import SwiftData
import MapKit

struct DetailView: View {
    @EnvironmentObject private var notificationManager: InAppNotificationManager
    @EnvironmentObject private var mapViewModel: MapViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: DPItem?
    @State private var showQRSheet = false
    
    var body: some View {
        NavigationView {
            List {
                if let selectedMarker = mapViewModel.selectedMarker, selectedMarker != KSearchMarkerId, let dpItem = selectedItem {
                    DigipinTileView(dpItem: dpItem) {
                        showQRSheet = true
                    }
                }
            }
            .navigationTitle(mapViewModel.selectedMarker ?? "No Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CButton.XMarkFillBtn {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        (mapViewModel.selectedMarker ?? "").copyToClipboard()
                        notificationManager.copiedToClipboardToast()
                    } label: {
                        Image(systemName: "document.on.document")
                            .font(.body)
                    }

                }
            }
        }
        .onAppear(perform: fetchItem)
        .onDisappear {
            try? modelContext.save()
        }
        .onChange(of: mapViewModel.selectedMarker, { _, _ in
            fetchItem()
        })
        .sheet(isPresented: $showQRSheet) {
            DigipinQRView(pin: mapViewModel.selectedMarker ?? "")
        }
        .presentationDetents([.height(350)])
        .presentationBackgroundInteraction(.enabled)
        .presentationDragIndicator(.visible)
    }
    
    private func fetchItem() {
        guard let selected = mapViewModel.selectedMarker else {
            selectedItem = nil
            return
        }
        
        let descriptor = FetchDescriptor<DPItem>(
            predicate: #Predicate { $0.id == selected && !$0.deleted },
        )
        
        do {
            let items = try modelContext.fetch(descriptor)
            selectedItem = items.first
        } catch {
            print("Error fetching item: \(error)")
            selectedItem = nil
        }
    }
}


#Preview {
    DetailView()
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
}
