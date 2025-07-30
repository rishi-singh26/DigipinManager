//
//  MapView.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject private var mapController: MapController
    @EnvironmentObject private var viewModel: MapViewModel
    
    var body: some View {
        ZStack {
            Map(position: $mapController.currentPosition)
                .mapStyle(mapController.selectedMapStyle)
            Image(systemName: "scope")
                .font(.title2)
                .foregroundColor(.primary)
        }
        .onAppear(perform: {
            viewModel.showBottomSheet = true
        })
        .sheet(isPresented: $viewModel.showBottomSheet) {
            BottomSheetView()
        }
        .overlay(alignment: .bottomTrailing) {
            BottomFloatingToolbar()
                .padding(.trailing, 15)
                .offset(y: viewModel.safeAreaBottomInset - 10)
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.safeAreaInsets.bottom
        } action: { newValue in
            viewModel.safeAreaBottomInset = newValue
        }
        
    }
    
    @ViewBuilder
    private func BottomFloatingToolbar() -> some View {
        VStack(spacing: 15) {
            Button {
                print("Map")
            } label: {
                Image(systemName: "map")
            }
            .padding(.horizontal, 10)
            Divider().frame(maxWidth: 30)
            Button {
                print("Location")
            } label: {
                Image(systemName: "location")
            }
            .padding(.horizontal, 10)
        }
        .font(.title3)
        .foregroundStyle(Color.primary)
        .padding(.vertical, 15)
        //.glassEffect(.regular, in: .capsule)
        // remove background in ios26
        .background(.thickMaterial, in: .rect(cornerRadius: 12))
        .opacity(viewModel.toolbarOpacity)
        .offset(y: -viewModel.sheetHeight)
        .animation(.interpolatingSpring(duration: viewModel.animationDuration, bounce: 0, initialVelocity: 0), value: viewModel.sheetHeight)
    }
}

#Preview {
    MapView()
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
}
