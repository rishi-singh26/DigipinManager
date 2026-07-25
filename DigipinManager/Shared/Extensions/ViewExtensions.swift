//
//  ViewExtensions.swift
//  DigipinManager
//
//  Created by Rishi Singh on 01/08/25.
//

import SwiftUI
import TipKit

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
    
    // Added for onboarding view.
    @ViewBuilder
    func setUpOnboarding() -> some View {
#if os(macOS)
        self
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(minHeight: 600)
#else
        if DeviceType.isIpad {
            // Makiing it fit on iPadOS 18+ devices
            if #available(iOS 18, *) {
                self
                    .presentationSizing(.fitted)
                    .padding(.horizontal, 25)
                    .padding(.bottom, 25)
            } else {
                self
            }
        } else {
            self
        }
#endif
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func withTipCloseStatusListner(_ tip: some Tip, onClose: @escaping () -> Void) -> some View {
        self
            .if(tip.status == .available, transform: { view in
                view
                    .task {
                        for await status in tip.statusUpdates {
                            if status == .invalidated(.tipClosed) {
                                onClose()
                                break // Exit the task to cancel listening
                            }
                        }
                    }
            })
    }
    
    /// Applies thin material on iOS 25 and below, and Liquid Glass on iOS 26+, using the provided shape.
    @ViewBuilder
    func withOSSurface<S: Shape>(_ shape: S) -> some View {
#if os(iOS)
        if #available(iOS 26, *) {
            self.glassEffect(in: shape)
        } else {
            self.background {
                shape
                    .fill(.thinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
            }
        }
#else
        self.background {
            shape
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
        }
#endif
    }
}
