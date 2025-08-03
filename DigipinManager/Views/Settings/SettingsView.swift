//
//  SettingsView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 03/08/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
//                Section {
//                    Label("Export Digipins", systemImage: "square.and.arrow.up")
//                    Label("Import Digipins", systemImage: "square.and.arrow.down")
//                }
                
                Section {
                    NavigationLink {
                        ExplanationView()
                    } label: {
                        Label("How DIGIPIN works", systemImage: "questionmark")
                    }
                }
                
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Digipin Manager", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
