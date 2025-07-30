//
//  ContentView.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        MapView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DPItem.self, inMemory: true)
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
}
