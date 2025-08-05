//
//  BottomSheetView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI
import SwiftData
import MapKit

struct BottomSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isNetworkConnected) private var isConnected
    @Environment(\.connectionType) private var connectionType
    
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var viewModel: MapViewModel
    @EnvironmentObject private var mapController: MapController
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var notificationManager: InAppNotificationManager
    // Sheet properties
    @FocusState private var isFocused: Bool
    @State private var showSettingsSheet: Bool = false
    @State private var haptic: Bool = false
    @State private var showNotNetworkSheet = false
    //
    @State private var showQRSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderBuilder()
            
            List {
                if let pinAddress = mapController.addressData.1, !viewModel.showSearchBar, let pin = mapController.digipin {
                    AddressTileBuilder(address: pinAddress, location: mapController.mapCenter, pin: pin)
                }
                
                if let location = mapController.searchLocation, viewModel.showSearchBar {
                    AddressTileBuilder(address: mapController.searchAddressData.1 ?? "", location: location, pin: viewModel.searchText)
                }
                
                DPItemsListView(searchText: viewModel.searchText)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.systemGroupedBackground))
        // Animating focus changes
        .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: isFocused)
        // Presentation modifiers
        .presentationDetents(viewModel.detents, selection: $viewModel.sheetDetent)
        .presentationBackgroundInteraction((isConnected ?? true) ? .enabled : .disabled)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self, of: handleGeometryProxy, action: handleGeometryChange)
        .ignoresSafeArea()
        .interactiveDismissDisabled()
        .sensoryFeedback(.impact, trigger: haptic)
        .onChange(of: isFocused, handleSearchFocusChange)
        .onChange(of: (isConnected ?? true), { _, new in
            showNotNetworkSheet = !new
        })
        .sheet(isPresented: $showNotNetworkSheet) {
            NoInternetView()
        }
        .sheet(isPresented: $mapController.showMapStyleSheet) {
            MapStylePickerView()
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
                .presentationDetents([.fraction(0.999)])
        }
        .sheet(isPresented: $appController.showOnboarding, content: {
            OnboardingView(tint: .accentColor, onContinue: appController.hideOnboardingSheet)
        })
        .sheet(isPresented: $showQRSheet) {
            if mapController.searchAddressData.1 != nil && viewModel.showSearchBar {
                DigipinQRView(pin: viewModel.searchText)
            } else {
                DigipinQRView(pin: mapController.digipin ?? "")
            }
        }
        .sheet(isPresented: Binding<Bool>(get: { viewModel.selectedMarker != nil }, set: { _ in viewModel.selectedMarker = nil })) {
            DetailView()
        }
    }
}

// MARK: - View builders
extension BottomSheetView {
    @ViewBuilder
    private func HeaderBuilder() -> some View {
        HStack(spacing: 10) {
            if !viewModel.showSearchBar {
                CButton.RoundBtn(symbol: "magnifyingglass") {
                    haptic.toggle()
                    withAnimation { viewModel.showSearchBar = true }
                    isFocused = true
                }
            }
            
            ZStack {
                if viewModel.showSearchBar {
                    SearchBarBuilder()
                } else {
                    PinViewBuilder()
                }
            }
            
            Button {
                haptic.toggle()
                if viewModel.showSearchBar {
                    isFocused = false
                    withAnimation { viewModel.showSearchBar = false }
                    viewModel.searchText = ""
                    mapController.searchLocation = nil
                    mapController.searchAddressData = (nil, nil)
                } else {
                    showSettingsSheet = true
                }
            } label: {
                ZStack {
                    if viewModel.showSearchBar {
                        CButton.RoundBtnLabel(symbol: "xmark")
                    } else {
                        CButton.RoundBtnLabel(symbol: "switch.2")
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: KHeaderHeight)
        .padding(.top, 5)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    @ViewBuilder
    private func SearchBarBuilder() -> some View {
        TextField("Search", text: $viewModel.searchText)
            .textInputAutocapitalization(.characters)
            .font(.title3.bold())
            .focused($isFocused)
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .frame(height: 48)
            .background(.gray.opacity(0.25), in: .capsule)
            .transition(.blurReplace)
            .onChange(of: viewModel.searchText) { old, new in
                if (new.count == 3 || new.count == 7) && old.count < new.count {
                    viewModel.searchText += "-"
                }
                guard let coords = mapController.getCoordinates(from: new) else { return }
                mapController.updatedMapPositionAndSearchLocation(with: coords)
                guard (isConnected ?? true) else { return }
                Task {
                    mapController.searchAddressData = await locationManager.getAddressFromLocation(coords)
                }
            }
    }
    
    @ViewBuilder
    private func PinViewBuilder() -> some View {
        HStack {
            Button {
                haptic.toggle()
                (mapController.digipin ?? "NA").copyToClipboard()
                notificationManager.showNotification(title: nil, message: "Copied to clipboard")
            } label: {
                Text(mapController.digipin ?? "Out of bounds")
                    .font(.title2.bold())
                    .contentTransition(.numericText())
            }
            .disabled(mapController.digipin == nil)
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
            .disabled(mapController.digipin == nil)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .transition(.blurReplace)
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


// MARK: - View Functions
extension BottomSheetView {
    private func handleSearchFocusChange(old: Bool, new: Bool) {
        if new {
            viewModel.sheetDetent = viewModel.highDetent
        }
    }
    
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
