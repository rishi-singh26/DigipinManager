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
                Section {
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Import Digipins", systemImage: "square.and.arrow.down")
                    }
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export Digipins", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section {
                    NavigationLink {
                        ExplanationView()
                    } label: {
                        Label("How DIGIPIN works", systemImage: "questionmark.circle")
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
