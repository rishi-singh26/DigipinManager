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
    
    @EnvironmentObject private var appController: AppController
    @EnvironmentObject private var viewModel: MapViewModel
    @EnvironmentObject private var mapController: MapController
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var notificationManager: InAppNotificationManager
    // Sheet properties
    @State private var showSettingsSheet: Bool = false
    @State private var showNotNetworkSheet = false
    //
    @State private var showQRSheet = false
    
    var body: some View {
        NavigationView {
            List {
                if let pinAddress = mapController.addressData.1, !viewModel.showSearchBar, let pin = mapController.digipin {
                    AddressTileBuilder(address: pinAddress, location: mapController.mapCenter, pin: pin)
                }
                
                if let location = appController.searchLocation, viewModel.showSearchBar {
                    AddressTileBuilder(address: appController.searchAddressData.1 ?? "", location: location, pin: viewModel.searchText)
                }
                
                DPItemsListView(searchText: viewModel.searchText)
            }
            .searchable(text: $viewModel.searchText, isPresented: $viewModel.showSearchBar.animation(), placement: .navigationBarDrawer(displayMode: .automatic), prompt: "DIGIPIN")
            .navigationTitle("Digipin Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Label("Options", systemImage: "switch.2")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        notificationManager.showCoordsToPinConverter()
                    } label: {
                        Label("Coordinates to DIGIPIN", systemImage: "point.bottomleft.forward.to.arrow.triangle.scurvepath")
                    }
                }
                ToolbarItem(placement: .title) {
                    PinViewBuilder()
                }
            }
        }
        // Presentation modifiers
        .presentationDetents(viewModel.detents, selection: $viewModel.sheetDetent)
        .presentationBackgroundInteraction((isConnected ?? true) ? .enabled : .disabled)
        .presentationCompactAdaptation(.none)
        .interactiveDismissDisabled()
        .presentationCornerRadius(viewModel.cornerRadius)
        .adaptiveSheet(400, isActive: viewModel.isLargeScreen)
        .onGeometryChange(for: CGFloat.self, of: handleGeometryProxy, action: handleGeometryChange)
        .ignoresSafeArea()
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
                .presentationDetents([.fraction(0.99)])
                .adaptiveSheet(400, isActive: viewModel.isLargeScreen)
        }
        .sheet(isPresented: $appController.showOnboarding) {
            locationManager.requestLocationPermission()
        } content: {
            OnboardingView(tint: .accentColor, onContinue: appController.hideOnboardingSheet)
        }
        .sheet(isPresented: $showQRSheet) {
            Group {
                if appController.searchAddressData.1 != nil && viewModel.showSearchBar {
                    DigipinQRView(pin: viewModel.searchText)
                } else {
                    DigipinQRView(pin: mapController.digipin ?? "")
                }
            }
            .presentationCornerRadius(viewModel.cornerRadius)
            .adaptiveSheet(400, isActive: viewModel.isLargeScreen)
        }
        .sheet(isPresented: Binding<Bool>(get: { viewModel.selectedMarker != nil }, set: { _ in viewModel.selectedMarker = nil })) {
            DetailView()
                .adaptiveSheet(400, isActive: viewModel.isLargeScreen)
                .presentationCornerRadius(viewModel.cornerRadius)
        }
        .onChange(of: viewModel.searchText, handleSearchTextChange)
    }
}

// MARK: - View builders
extension BottomSheetView {
    @ViewBuilder
    private func PinViewBuilder() -> some View {
        let copyToClipboardTip = CopyToClipboardTip()
        let addToPinnedListTip = AddToPinnedListTip()
        
        HStack {
            Button {
                (mapController.digipin ?? "NA").copyToClipboard()
                notificationManager.copiedToClipboardToast()
            } label: {
                Text(mapController.digipin ?? "Out of bounds")
                    .font(.title2.bold())
                    .contentTransition(.numericText())
            }
            .popoverTip(copyToClipboardTip)
            .help("Copy DIGIPIN")
            .disabled(mapController.digipin == nil)
            .buttonStyle(.plain)
            .withTipCloseStatusListner(copyToClipboardTip, onClose: {
                AddToPinnedListTip.show = true
            })
            
            if viewModel.sheetHeight < 150 {
                Spacer()
                Button {
                    saveCorrentLocDigipin()
                } label: {
                    Image(systemName: "pin")
                        .font(.callout)
                }
                .popoverTip(addToPinnedListTip)
                .help("Add DIGIPIN to pinned list")
                .disabled(mapController.digipin == nil)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .withTipCloseStatusListner(addToPinnedListTip, onClose: {
                    ScopeTip.show = true
                })
            }
        }
        .animation(.default, value: viewModel.sheetHeight < 150)
//        .padding(.horizontal, 20)
        .frame(width: 230, height: 48)
        .frame(maxWidth: .infinity, alignment: .center)
        .transition(.blurReplace)
    }
    
    @ViewBuilder
    private func AddressTileBuilder(address: String, location: CLLocationCoordinate2D?, pin: String) -> some View {
        DigipinTileView(address: address, location: location, pin: pin) {
            showQRSheet = true
        } onAddToList: {
            saveDigipin(pin: pin, address: address)
        }
    }
}


// MARK: - View Functions
extension BottomSheetView {
    private func handleGeometryProxy(proxy: GeometryProxy) -> CGFloat {
        max(min(proxy.size.height + 20, 420 + viewModel.safeAreaBottomInset), 0)
    }
    
    private func handleGeometryChange(oldValue: CGFloat, newValue: CGFloat) {
        // Toolbar items animation only for mobile screens
        guard viewModel.isLargeScreen == false else { return }
        
        // limiting the offset to 300, so toolbar opacity effect will be visible
        viewModel.sheetHeight = min(newValue, MapViewModel.sheetMidHeight + viewModel.safeAreaBottomInset)
        
        // Calculate toolbar opacity
        let progress = max(min((newValue - (MapViewModel.sheetMidHeight + viewModel.safeAreaBottomInset)) / 50, 1), 0)
        viewModel.toolbarOpacity = 1 - progress
        
        // Calculate animation duration
        let diff = abs(newValue - oldValue)
        viewModel.animationDuration = max(min(diff / 100, 0.3), 0)
    }
    
    private func handleSearchTextChange(old: String, new: String) {
        let filtered = new.uppercased().filter { KDigipinCharacters.contains($0) }
        
        var formatted = ""
        for (index, char) in filtered.enumerated() {
            if index == 3 || index == 6 {
                formatted.append("-")
            }
            formatted.append(char)
            
            if formatted.count == 12 { break }
        }
        
        // Update only if the value actually changed
        if viewModel.searchText != formatted {
            viewModel.searchText = formatted
        }
        
        if let coords = DigipinUtility.getCoordinates(from: new) {
            mapController.updatedMapPosition(with: coords)
            appController.updateSearchLocation(with: coords)
            guard (isConnected ?? true) else { return }
            Task {
                let searchAdderss = try? await AddressUtility.shared.getAddressFromLocation(coords)
                appController.searchAddressData = searchAdderss ?? (nil, nil)
            }
        } else {
            appController.updateSearchLocation(with: nil)
        }
    }
    
    private func saveCorrentLocDigipin() {
        Task {
            let result = await mapController.saveCurrentLocDigipin(modelContext)
            handlePinSaveResult(result: result)
        }
    }
    
    private func saveDigipin(pin: String, address: String) {
        let result = mapController.saveToPinnedListIfNotExist(pin: pin, address: address, modelContext)
        handlePinSaveResult(result: result)
    }
    
    private func handlePinSaveResult(result: (Bool, String?)) {
        if result.0 {
            notificationManager.showToast(title: "Added to pinned list")
        } else if let message = result.1 {
            notificationManager.showToast(title: message, type: .warning)
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
