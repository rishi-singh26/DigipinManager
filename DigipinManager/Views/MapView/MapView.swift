//
//  MapView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import MapKit
import SwiftData
import TipKit

struct MapItem: Identifiable {
    let id: String
}

struct MapView: View {
    @Query(filter: #Predicate<DPItem> { !$0.deleted }) private var dpItems: [DPItem]
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @EnvironmentObject private var mapController: MapController
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var viewModel: MapViewModel
    @StateObject private var converterModel = CoordinateToPinNotificationViewModel.shared

    @Namespace var mapScope
    
    private let scopeTip = ScopeTip()
    
    var body: some View {
        ZStack(alignment: .center) {
            Map(position: $mapController.position, selection: $viewModel.selectedMarker) {
                UserAnnotation()
                MapPolyline(points: MapController.boundPoints)
                    .stroke(.primary, style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round))
                if let searchLocation = appController.searchLocation {
                    Marker("Searched DIGIPIN", coordinate: searchLocation)
                        .mapItemDetailSelectionAccessory(.sheet)
                }
                
                if let convertedLocation = converterModel.location {
                    Marker("Searched Location", coordinate: convertedLocation)
                        .mapItemDetailSelectionAccessory(.sheet)
                }
                
                ForEach(dpItems) {
                    Marker($0.id, coordinate: CLLocationCoordinate2DMake($0.latitude, $0.longitude))
                        .tag($0.id)
                }
            }
            .mapStyle(mapController.selectedMapStyleType.mapStyle)
            .mapControls {
                if locationManager.hasLocationPermission {
                    MapUserLocationButton(scope: mapScope)
                }
                MapScaleView(anchorEdge: .leading, scope: mapScope)
                MapPitchToggle(scope: mapScope)
                MapCompass(scope: mapScope)
            }
            .mapControlVisibility(.visible)
            .onMapCameraChange(frequency: .onEnd, handleCameraMoveEnd)
            .onMapCameraChange(frequency: .continuous, handleCameraMove)
            
            ScopeBuilder()
            
            TipView(scopeTip, arrowEdge: .bottom)
                .padding(.horizontal, 20)
                .padding(.bottom, 180)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: {
            viewModel.showBottomSheet = true
        })
        .sheet(isPresented: $viewModel.showBottomSheet) {
            BottomSheetView()
        }
        .overlay {
            if viewModel.showBottomSheet {
                BottomFloatingToolbar()
            }
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.safeAreaInsets.bottom
        } action: { newValue in
            viewModel.safeAreaBottomInset = newValue
        }
        .onGeometryChange(for: Bool.self) {
            $0.size.width > 600
        } action: { newValue in
            viewModel.handleScreenResize(with: newValue)
        }
        .onChange(of: viewModel.showBottomSheet) { _, newValue in
            // Update map center, DIGIPIN and Address when showBottomSheet is set to true
            if newValue, let region = mapController.position.region {
                mapController.onMapRegionChanged(region)
            }
        }
        .onTapGesture {
            viewModel.dismissMapStylePicker()
        }
    }
    
    @ViewBuilder
    private func ScopeBuilder() -> some View {
        Image(systemName: "scope")
            .font(.title2)
            .foregroundColor(mapController.selectedMapStyleType == .imagery ? .white : .primary)
    }
    
    private func handleCameraMoveEnd(context: MapCameraUpdateContext) {
        // Update map center, DIGIPIN and Address only when bottom sheet is shown
        if viewModel.showBottomSheet {
            mapController.onMapRegionChanged(context.region)
        }
    }
    
    private func handleCameraMove(context: MapCameraUpdateContext) {
        viewModel.dismissMapStylePicker()
    }
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let container = try! ModelContainer(for: DPItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        // Add sample data
        let sampleDPItems = [
            DPItem(pin: "4P3-33C-4635", address: "Address Data", latitude: 13.006003, longitude: 77.751144),
            DPItem(pin: "4P3-33C-5MMJ", address: "Address Data", latitude: 13.005222, longitude: 77.752166),
            DPItem(pin: "4P3-33C-P7JF", address: "Address Data", latitude: 13.004407, longitude: 77.753131),
            DPItem(pin: "4P3-33C-T9MF", address: "Address Data", latitude: 13.004709, longitude: 77.754909)
        ]
        
        for item in sampleDPItems {
            container.mainContext.insert(item)
        }
        
        return container
    }()
    
    ContentView()
        .environmentObject(AppController.shared)
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(InAppNotificationManager.shared)
        .modelContainer(container)
}
