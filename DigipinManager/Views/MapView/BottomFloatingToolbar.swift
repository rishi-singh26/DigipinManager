//
//  BottomFloatingToolbar.swift
//  DigipinManager
//
//  Created by Rishi Singh on 01/08/26.
//

import SwiftUI
import SwiftData

struct BottomFloatingToolbar : View {
    @EnvironmentObject private var viewModel: MapViewModel
    @EnvironmentObject private var locationManager: LocationManager
    
    let alignment: Alignment = .bottomTrailing
    let edge: CGFloat = 45
    
    var body: some View {
        AnimatedMenu(alignment: alignment,
                     progress: viewModel.mapStylePickerProgress,
                     labelSize: .init(width: edge, height: locationManager.hasLocationPermission ? edge : 90)) {
            MapStylePickerView()
        } label: {
            BuildLabel()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .padding(15)
        .opacity(viewModel.toolbarOpacity)
        .offset(y: DeviceType.isIpad ? 0 : -viewModel.sheetHeight + 30)
        .animation(.interpolatingSpring(duration: viewModel.animationDuration, bounce: 0, initialVelocity: 0), value: viewModel.sheetHeight)
    }
    
    @ViewBuilder
    private func BuildLabel() -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(viewModel.mapStylePcikerAnimation) {
                    viewModel.mapStylePickerProgress = 1
                }
            } label: {
                Image(systemName: "map")
                    .foregroundStyle(Color.accentColor)
                    .frame(width: edge, height: edge)
            }
            
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
                        .frame(width: edge, height: edge)
                }
            }
        }
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
