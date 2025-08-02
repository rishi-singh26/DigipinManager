//
//  BottomSheetView.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import SwiftData
import MapKit

struct BottomSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var viewModel: MapViewModel
    @EnvironmentObject private var mapController: MapController
    @EnvironmentObject private var locationManager: LocationManager
    // Sheet properties
    @FocusState private var isFocused: Bool
    @State private var showSettingsSheet: Bool = false
    @State private var showSearchBar: Bool = false
    @State private var haptic: Bool = false
    //
    @State private var showQRSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderBuilder()
                List {
                    if let pinAddress = mapController.addressData.1, !showSearchBar, let pin = mapController.digipin {
                        AddressTileBuilder(address: pinAddress, location: mapController.mapCenter, pin: pin)
                    }
                    
                    if let searchAddress = mapController.searchAddressData.1, showSearchBar {
                        AddressTileBuilder(address: searchAddress, location: mapController.searchLocation, pin: mapController.searchText)
                    }
                    
                    DPItemsListView(searchText: mapController.searchText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        // Animating focus changes
        .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: isFocused)
        // Presentation modifiers
        .presentationDetents([.height(80), .height(350)], selection: $viewModel.sheetDetent)
        .presentationBackground(.thickMaterial)
        .presentationBackgroundInteraction(.enabled)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self, of: handleGeometryProxy, action: handleGeometryChange)
        .ignoresSafeArea()
        .interactiveDismissDisabled()
        .sensoryFeedback(.impact, trigger: haptic)
        .sheet(isPresented: $showSettingsSheet) { }
        .sheet(isPresented: $showQRSheet) {
            if mapController.searchAddressData.1 != nil && showSearchBar {
                DigipinQRView(pin: mapController.searchText)
            } else {
                DigipinQRView(pin: mapController.digipin ?? "")
            }
        }
        .sheet(isPresented: Binding<Bool>(get: { mapController.selectedMarker != nil }, set: { _ in mapController.selectedMarker = nil })) {
            DetailView()
        }
    }
}

// MARK: - View builders
extension BottomSheetView {
    @ViewBuilder
    private func HeaderBuilder() -> some View {
        HStack(spacing: 10) {
            if !showSearchBar {
                CButton.RoundBtn(symbol: "magnifyingglass") {
                    haptic.toggle()
                    withAnimation { showSearchBar = true }
                    isFocused = true
                }
            }
            
            ZStack {
                if showSearchBar {
                    SearchBarBuilder()
                } else {
                    PinViewBuilder()
                }
            }
            
            Button {
                haptic.toggle()
                if showSearchBar {
                    isFocused = false
                    withAnimation { showSearchBar = false }
                    mapController.searchText = ""
                    mapController.searchLocation = nil
                    mapController.searchAddressData = (nil, nil)
                } else {
                    showSettingsSheet = true
                }
            } label: {
                ZStack {
                    if showSearchBar {
                        CButton.RoundBtnLabel(symbol: "xmark")
                    } else {
                        CButton.RoundBtnLabel(symbol: "switch.2")
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 80)
        .padding(.top, 5)
    }
    
    @ViewBuilder
    private func SearchBarBuilder() -> some View {
        TextField("Search", text: $mapController.searchText)
            .textInputAutocapitalization(.characters)
            .font(.title3.bold())
            .focused($isFocused)
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .frame(height: 48)
            .background(.gray.opacity(0.25), in: .capsule)
            .transition(.blurReplace)
            .onChange(of: mapController.searchText) { _, new in
                if let coords = mapController.getCoordinates(from: new) {
                    mapController.updatedMapPositionAndSearchLocation(with: coords)
                    Task {
                        mapController.searchAddressData = await locationManager.getAddressFromLocation(coords)
                    }
                }
            }
    }
    
    @ViewBuilder
    private func PinViewBuilder() -> some View {
        HStack {
            Button {
                haptic.toggle()
                (mapController.digipin ?? "NA").copyToClipboard()
            } label: {
                Text(mapController.digipin ?? "Out of bounds")
                    .font(.title2.bold())
                    .contentTransition(.numericText())
                //.background(.gray.opacity(0.25), in: .capsule)
                    .transition(.blurReplace)
            }
            .buttonStyle(.plain)
            
            Menu {
                Button {
                    (mapController.digipin ?? "NA").copyToClipboard()
                } label: {
                    Label("Copy", systemImage: "document.on.document")
                }
                Button {
                    saveCorrentLocDigipin()
                } label: {
                    Label("Pin to list", systemImage: "pin")
                }
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.body)
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func AddressTileBuilder(address: String, location: CLLocationCoordinate2D?, pin: String) -> some View {
        DigipinTileView(address: address, location: location, pin: pin) {
            showQRSheet = true
        } action2: {
            saveCorrentLocDigipin()
        }
    }
}

// MARK: - Data Functions
extension BottomSheetView {
    private func getCurrentLocationDetails(pin: String) -> String {
        String.createSharePinData(
            address: mapController.addressData.1,
            location: mapController.mapCenter,
            pin: pin
        )
    }

    private func getSearchLocationDetails(pin: String) -> String {
        String.createSharePinData(
            address: mapController.searchAddressData.1,
            location: mapController.searchLocation,
            pin: pin
        )
    }
}


// MARK: - View Functions
extension BottomSheetView {
    private func handleGeometryProxy(proxy: GeometryProxy) -> CGFloat {
        max(min(proxy.size.height, 400 + viewModel.safeAreaBottomInset), 0)
    }
    
    private func handleGeometryChange(oldValue: CGFloat, newValue: CGFloat) {
        // limiting the offset to 300, so toolbar opacity effect will be visible
        viewModel.sheetHeight = min(newValue, 350 + viewModel.safeAreaBottomInset)
        
        // Calculate toolbar opacity
        let progress = max(min((newValue - (350 + viewModel.safeAreaBottomInset)) / 50, 1), 0)
        viewModel.toolbarOpacity = 1 - progress
        
        // Calculate animation duration
        let diff = abs(newValue - oldValue)
        viewModel.animationDuration = max(min(diff / 100, 0.3), 0)
    }
    
    private func saveCorrentLocDigipin() {
        guard let currentPosition = mapController.mapCenter else { return }
        guard let pin = mapController.digipin else { return }
        Task {
            let result = await locationManager.getAddressFromLocation(currentPosition)
            guard let address = result.1  else { return }
            mapController.saveToPinnedList(pin: pin, address: address, modelContext)
        }
    }
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let container = try! ModelContainer(for: DPItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        // Add sample data
        let sampleDPItems = [
            DPItem(pin: "4P3-33C-4635", latitude: 13.006003, longitude: 77.751144),
            DPItem(pin: "4P3-33C-5MMJ", latitude: 13.005222, longitude: 77.752166),
            DPItem(pin: "4P3-33C-P7JF", latitude: 13.004407, longitude: 77.753131),
            DPItem(pin: "4P3-33C-T9MF", latitude: 13.004709, longitude: 77.754909)
        ]
        
        for item in sampleDPItems {
            container.mainContext.insert(item)
        }
        
        return container
    }()
    
    ContentView()
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
        .modelContainer(container)
}
