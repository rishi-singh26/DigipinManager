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
    
    @Query private var dpItems: [DPItem]
    
    init(searchText: String) {
        self.searchText = searchText
        
        // Create predicate for filtering by pin (id) based on searchText
        let predicate: Predicate<DPItem>
        if searchText.isEmpty {
            predicate = #Predicate<DPItem> { item in
                !item.deleted
            }
        } else {
            predicate = #Predicate<DPItem> { item in
                !item.deleted && item.id.localizedStandardContains(searchText)
            }
        }
        
        // Query with predicate, sorted by updatedAt descending, limited to 100 items
        _dpItems = Query(
            filter: predicate,
            sort: [SortDescriptor(\DPItem.updatedAt, order: .reverse)],
            animation: .default
        )
    }
    
    var body: some View {
        ForEach(Array(dpItems.prefix(100)), id: \.id) { item in
            DPItemRowView(item: item)
        }
    }
}

struct DPItemRowView: View {
    let item: DPItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Pin: \(item.pin)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if item.favourite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if !item.address.isEmpty {
                Text(item.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text("Lat: \(item.latitude, specifier: "%.6f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Lng: \(item.longitude, specifier: "%.6f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(item.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let container = try! ModelContainer(for: DPItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        // Add sample data
        let sampleDPItems = [
            DPItem(pin: "xxx-xxx-xxxx", latitude: 0, longitude: 0),
            DPItem(pin: "yyyy-xxx-xxxx", latitude: 0, longitude: 0)
        ]
        
        for item in sampleDPItems {
            container.mainContext.insert(item)
        }
        
        return container
    }()
    
    DPItemsListView(searchText: "")
        .modelContainer(container)
}
