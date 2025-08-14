//
//  SettingsView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 03/08/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showURLConfirmation: Bool = false
    @State private var selectedURLForConfirmation: String?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink {
                        ImportView()
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
                    Button {
                        selectedURLForConfirmation = "https://www.indiapost.gov.in/digipin"
                        showURLConfirmation = true
                    } label: {
                        CustomLabel(leadingImageName: "book.pages", trailingImageName: "arrow.up.right", title: "Learn More")
                    }
                    .help("Learn more about how DIGIPIN works")
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
            .withURLConfirmation($showURLConfirmation, url: selectedURLForConfirmation ?? "")
        }
    }
}

#Preview {
    SettingsView()
}
