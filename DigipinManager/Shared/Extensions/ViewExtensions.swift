//
//  ViewExtensions.swift
//  DigipinManager
//
//  Created by Rishi Singh on 01/08/25.
//

import SwiftUI

extension View {
    func shareSheet(isPresented: Binding<Bool>, items: [Any], excludedActivityTypes: [Any]? = nil) -> some View {
#if os(iOS)
        self.sheet(isPresented: isPresented) {
            ShareSheet(items: items, excludedActivityTypes: excludedActivityTypes as? [UIActivity.ActivityType])
        }
#elseif os(macOS)
        self.background(
            EmptyView()
                .sheet(isPresented: isPresented) {
                    ShareSheet(items: items)
                        .frame(width: 1, height: 1) // Minimal frame for macOS
                }
        )
#else
        self // For other platforms, return the view unchanged
#endif
    }
    
    @ViewBuilder
    func withURLConfirmation(_ presented: Binding<Bool>, url: String) -> some View {
        self
            .confirmationDialog("Open URL?", isPresented: presented) {
                Button("Open") {
                    guard let url = URL(string: url) else { return }
                    url.open()
                }
                Button("Copy") {
                    url.copyToClipboard()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Do you want to open this URL?\n\(url)")
            }
    }
    
    
    // Added for onboarding view. Custom blur slide effect
    @ViewBuilder
    func blurSlide(_ show: Bool) -> some View {
        self
        // Groups the view and adds blur to the grouped view rather then applying blur to each node view
            .compositingGroup()
            .blur(radius: show ? 0 : 10)
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 100)
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
