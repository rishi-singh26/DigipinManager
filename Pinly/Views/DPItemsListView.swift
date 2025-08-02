//
//  DPItemsListView.swift
//  Pinly
//
//  Created by Rishi Singh on 31/07/25.
//

import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

struct DPItemsListView: View {
    let searchText: String
    
    @Query private var favouriteDPItems: [DPItem]
    @Query private var dpItems: [DPItem]
    
    init(searchText: String) {
        self.searchText = searchText
        
        _dpItems = getDPItemsQuery(favourite: false)
        _favouriteDPItems = getDPItemsQuery(favourite: true)
    }
    
    var body: some View {
        if !favouriteDPItems.isEmpty {
            Section("Favourites") {
                ForEach(Array(favouriteDPItems), id: \.id) { item in
                    DPItemRowView(item: item)
                }
            }
        }
        
        if !dpItems.isEmpty {
            Section("Pinned Items") {
                ForEach(Array(dpItems), id: \.id) { item in
                    DPItemRowView(item: item)
                }
            }
        }
    }
    
    private func getDPItemsQuery(favourite: Bool) -> Query<Array<DPItem>.Element, [DPItem]> {
        let predicate: Predicate<DPItem>
        if searchText.isEmpty {
            predicate = #Predicate<DPItem> { item in
                !item.deleted && item.favourite == favourite
            }
        } else {
            predicate = #Predicate<DPItem> { item in
                !item.deleted && item.id.localizedStandardContains(searchText) && item.favourite == favourite
            }
        }
        
        // Query with predicate, sorted by createdAt descending
        return Query(
            filter: predicate,
            sort: [SortDescriptor(\DPItem.createdAt, order: .reverse)],
            animation: .default
        )
    }
}

struct DPItemRowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var mapViewModel: MapViewModel
    
    let item: DPItem
    
    var body: some View {
        Button(action: {
            mapViewModel.sheetDetent = mapViewModel.midDetent
            mapViewModel.selectedMarker = item.id
        }, label: {
            DPItemsListTile()
        })
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                BuildFavouriteButton()
                    .labelsHidden()
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                BuildDeleteButton()
                    .labelsHidden()
            }
            .contextMenu {
                BuildFavouriteButton(addTint: false)
                BuildDeleteButton(addTint: false)
            }
    }
    
    @ViewBuilder
    private func DPItemsListTile() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.id)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if item.favourite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            HStack {
                Text(item.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(item.createdAt.formatRelativeString())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func BuildDeleteButton(addTint: Bool = true) -> some View {
        Button(role: .destructive) {
            modelContext.delete(item)
            try? modelContext.save()
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .help("Permanently delete DIGIPIN")
        .tint(addTint ? .red : nil)
    }
    
    @ViewBuilder
    private func BuildFavouriteButton(addTint: Bool = true) -> some View {
        Button {
            item.favourite.toggle()
            try? modelContext.save()
        } label: {
            Label(item.favourite ? "Remove Favourite" : "Mark Favourite", systemImage: item.favourite ? "star.fill" : "star")
        }
        .help("Mark DIGIPIN as favourite")
        .tint(addTint ? .orange : nil)
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
    
    ContentView()
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
        .modelContainer(container)
}
