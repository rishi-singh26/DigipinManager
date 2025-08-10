//
//  MapView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import MapKit
import SwiftData

struct MapItem: Identifiable {
    let id: String
}

struct MapView: View {
    @Query private var dpItems: [DPItem]
    
    @EnvironmentObject private var mapController: MapController
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var viewModel: MapViewModel

    @Namespace var mapScope
    
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
                
                ForEach(dpItems) {
                    Marker($0.id, coordinate: CLLocationCoordinate2DMake($0.latitude, $0.longitude))
                        .mapItemDetailSelectionAccessory(.sheet)
                        .tag($0.id)
                }
            }
            .mapStyle(mapController.selectedMapStyleType.mapStyle)
            .mapControls {
                if locationManager.hasLocationPermission {
                    MapUserLocationButton(scope: mapScope)
                }
                MapScaleView(anchorEdge: .leading, scope: mapScope)
                //MapPitchToggle(scope: mapScope)
                MapCompass(scope: mapScope)
            }
            .mapControlVisibility(.visible)
            .onMapCameraChange(frequency: .onEnd, handleCameraMoveEnd)
            
            ScopeBuilder()
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
                mapController.showMapStyleSheet = true
            } label: {
                Image(systemName: "map")
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 10)
            
            if !locationManager.hasLocationPermission {
                Divider().frame(maxWidth: 30)
                Button {
                    if locationManager.canAskForPermission {
                        locationManager.requestLocationPermission()
                    } else {
                        if let url = URL(string: UIApplication.openSettingsURLString),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                } label: {
                    Image(systemName: "location.slash")
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.horizontal, 10)
            }
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
    private func ScopeBuilder() -> some View {
        Image(systemName: "scope")
            .font(.title2)
            .foregroundColor(.primary)
    }
    
    private func handleCameraMoveEnd(context: MapCameraUpdateContext) {
        mapController.mapCenter = context.region.center
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
        .modelContainer(container)
}
