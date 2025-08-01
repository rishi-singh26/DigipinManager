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
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var viewModel: MapViewModel
    
    @State private var searchText: String = ""
    @Namespace var mapScope
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Map(position: $mapController.position) {
                    UserAnnotation()
                    MapPolyline(points: MapController.boundPoints)
                        .stroke(.primary, style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    if let searchLocation = mapController.searchLocation {
                        Marker("Searched DIGIPIN", coordinate: searchLocation)
                            .mapItemDetailSelectionAccessory(.sheet)
                    }
                }
                .mapStyle(mapController.selectedMapStyle)
                .mapControls {
                    MapUserLocationButton(scope: mapScope)
                    MapScaleView(anchorEdge: .leading, scope: mapScope)
                    //MapPitchToggle(scope: mapScope)
                    MapCompass(scope: mapScope)
                }
                .mapControlVisibility(.visible)
                .onMapCameraChange(frequency: .onEnd, handleCameraMoveEnd)
                
                ScopeBuilder(geometry: geometry)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: {
            viewModel.showBottomSheet = true
        })
        .sheet(isPresented: $viewModel.showBottomSheet) {
            BottomSheetView()
        }
        .overlay(alignment: .bottomTrailing) {
            BottomFloatingToolbar()
                .padding(.trailing, 10)
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
        )
        .opacity(viewModel.toolbarOpacity)
        .offset(y: -viewModel.sheetHeight)
        .animation(.interpolatingSpring(duration: viewModel.animationDuration, bounce: 0, initialVelocity: 0), value: viewModel.sheetHeight)
    }
    
    @ViewBuilder
    private func ScopeBuilder(geometry: GeometryProxy) -> some View {
        Image(systemName: "scope")
            .font(.title2)
            .foregroundColor(.primary)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
    
    private func handleCameraMoveEnd(context: MapCameraUpdateContext) {
        let center = context.region.center
        mapController.mapCenter = center
        Task {
            let result = await locationManager.getAddressFromLocation(
                Coordinate(latitude: center.latitude, longitude: center.longitude)
            )
            withAnimation {
                mapController.addressData = result
            }
        }
    }
}

#Preview {
    MapView()
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
}
