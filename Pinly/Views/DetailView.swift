//
//  DetailView.swift
//  Pinly
//
//  Created by Rishi Singh on 02/08/25.
//

import SwiftUI
import SwiftData
import MapKit

struct DetailView: View {
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
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear(perform: fetchItem)
        .onChange(of: mapViewModel.selectedMarker, { _, _ in
            fetchItem()
        })
        .sheet(isPresented: $showQRSheet) {
            DigipinQRView(pin: mapViewModel.selectedMarker ?? "")
        }
        .presentationDetents([.height(350)])
        .presentationBackgroundInteraction(.enabled)
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
}
