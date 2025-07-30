//
//  BottomSheetView.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI

struct BottomSheetView: View {
    @EnvironmentObject private var viewModel: MapViewModel
    // Sheet properties
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool
    @State private var showSettingsSheet = false
    
    var body: some View {
        ScrollView {
            
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 10) {
                TextField("Search", text: $searchText)
                    .focused($isFocused)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.gray.opacity(0.25), in: .capsule)
                
                // Profile/Close Button
                Button {
                    if isFocused {
                        isFocused = false
                    } else {
                        showSettingsSheet = true
                    }
                } label: {
                    ZStack {
                        if isFocused {
                            ActionBtnBuilder(symbol: "xmark")
                        } else {
                            ActionBtnBuilder(symbol: "switch.2")
                        }
                    }
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 8)
            .frame(height: 80)
            .padding(.top, 5)
        }
        // Animating focus changes
        .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: isFocused)
        // Update sheet height on textfield focus
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                viewModel.sheetDetent = .large
            } else if viewModel.sheetHeight > 350 {
                viewModel.sheetDetent = .height(350)
            }
        }
        // Presentation modifiers
        .presentationDetents([.height(80), .height(350), .large], selection: $viewModel.sheetDetent)
        .presentationBackgroundInteraction(.enabled)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) {
            max(min($0.size.height, 400 + viewModel.safeAreaBottomInset), 0)
        } action: { oldValue, newValue in
            // limiting the offset to 300, so toolbar opacity effect will be visible
            viewModel.sheetHeight = min(newValue, 350 + viewModel.safeAreaBottomInset)
            
            // Calculate toolbar opacity
            let progress = max(min((newValue - (350 + viewModel.safeAreaBottomInset)) / 50, 1), 0)
            viewModel.toolbarOpacity = 1 - progress
            
            // Calculate animation duration
            let diff = abs(newValue - oldValue)
            viewModel.animationDuration = max(min(diff / 100, 0.3), 0)
        }
        .ignoresSafeArea()
        .interactiveDismissDisabled()
        .sheet(isPresented: $showSettingsSheet) {
            
        }
    }
    
    @ViewBuilder
    private func ActionBtnBuilder(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(width: 48, height: 48)
            .background(.gray.opacity(0.25), in: .circle)
        //.glassEffect(in: .circle)
            .transition(.blurReplace)
    }
}

#Preview {
    MapView()
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
}
