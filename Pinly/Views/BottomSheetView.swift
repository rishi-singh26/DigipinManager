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
    @EnvironmentObject private var viewModel: MapViewModel
    @EnvironmentObject private var mapController: MapController
    @EnvironmentObject private var locationManager: LocationManager
    // Sheet properties
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool
    @State private var showSettingsSheet: Bool = false
    @State private var showSearchBar: Bool = false
    @State private var haptic: Bool = false
    //
    @State private var showQRSheet = false
    @State private var qrCodePin = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderBuilder()
                List {
                    if let pinAddress = mapController.addressData.1, !showSearchBar, let pin = mapController.digipin {
                        AddressTileBuilder(address: pinAddress, location: mapController.mapCenter, pin: pin)
                    }
                    
                    if let searchAddress = mapController.searchAddressData.1, showSearchBar {
                        AddressTileBuilder(address: searchAddress, location: mapController.searchLocation, pin: searchText)
                    }
                    
                    DPItemsListView(searchText: searchText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        // Animating focus changes
        .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: isFocused)
        // Update sheet height on textfield focus
        .onChange(of: isFocused, handleFocusChange)
        // Presentation modifiers
        .presentationDetents([.height(80), .height(320), .fraction(0.999)], selection: $viewModel.sheetDetent)
        .presentationBackground(.thickMaterial)
        .presentationBackgroundInteraction(.enabled)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self, of: handleGeometryProxy, action: handleGeometryChange)
        .ignoresSafeArea()
        .interactiveDismissDisabled()
        .sensoryFeedback(.impact, trigger: haptic)
        .sheet(isPresented: $showSettingsSheet) { }
        .sheet(isPresented: $showQRSheet) {
            VStack {
                HStack {
                    Text(qrCodePin)
                    Spacer()
                    Button {
                        showQRSheet = false
                    } label: {
                        ActionBtnBuilder(symbol: "xmark.circle.fill")
                    }
                }
                .padding()
                QRCodeView(inputText: qrCodePin, headerText: qrCodePin)
                    .presentationDetents([.fraction(0.65)])
                    .presentationBackground(.thinMaterial)
                    .navigationTitle("Hello")
                    .navigationBarTitleDisplayMode(.inline)
                
                Spacer()
            }
        }
    }
}
//39J-49L-KM47
// MARK: - View builders
extension BottomSheetView {
    @ViewBuilder
    private func HeaderBuilder() -> some View {
        HStack(spacing: 10) {
            if !showSearchBar {
                Button {
                    haptic.toggle()
                    withAnimation { showSearchBar = true }
                    isFocused = true
                } label: {
                    ActionBtnBuilder(symbol: "magnifyingglass")
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
                    searchText = ""
                    mapController.searchLocation = nil
                    mapController.searchAddressData = (nil, nil)
                } else {
                    showSettingsSheet = true
                }
            } label: {
                ZStack {
                    if showSearchBar {
                        ActionBtnBuilder(symbol: "xmark")
                    } else {
                        ActionBtnBuilder(symbol: "switch.2")
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
        TextField("Search", text: $searchText)
            .textInputAutocapitalization(.characters)
            .font(.title3.bold())
            .focused($isFocused)
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .frame(height: 48)
            .background(.gray.opacity(0.25), in: .capsule)
            .transition(.blurReplace)
            .onChange(of: searchText) { _, new in
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
        Menu {
            Button {
                (mapController.digipin ?? "NA").copyToClipboard()
            } label: {
                Label("Copy", systemImage: "document.on.document")
            }
            Button {} label: {
                Label("Add to list", systemImage: "list.bullet.rectangle.portrait")
            }
        } label: {
            Text(mapController.digipin ?? "Out of bounds")
                .font(.title2.bold())
                .contentTransition(.numericText())
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                //.background(.gray.opacity(0.25), in: .capsule)
                .transition(.blurReplace)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func ActionBtnBuilder(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(width: 48, height: 48)
            .background(.gray.opacity(0.15), in: .circle)
        //.glassEffect(in: .circle)
            .transition(.blurReplace)
    }
    
    @ViewBuilder
    private func AddressTileBuilder(address: String, location: CLLocationCoordinate2D?, pin: String) -> some View {
        Section {
            Text(address)
                .lineLimit(2, reservesSpace: true)
            LatLonView(location, prefix: "Coordinates: ")
            HStack {
                ShareLink(item: getLocationDetails(address: address, location: location, pin: pin)) {
                    ReactBtnLableBuilder(symbol: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                Spacer()
                RectActionBtnBuilder(symbol: "qrcode", helpText: "Share DIGIPIN details via QR code") {
                    showQRSheet = true
                    qrCodePin = pin
                }
                Spacer()
                RectActionBtnBuilder(symbol: "list.bullet.rectangle.portrait", helpText: "Save DIGIPIN to list") {
                    print("Hello w")
                }
                Spacer()
                Menu {
                    ShareLink("Share Coordinates", item: location?.toString() ?? "")
                    ShareLink("Share DIGIPIN", item: pin)
                } label: {
                    ReactBtnLableBuilder(symbol: "ellipsis")
                }
            }
        }
    }
    
    @ViewBuilder
    private func RectActionBtnBuilder(symbol: String, helpText: String = "", action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            ReactBtnLableBuilder(symbol: symbol)
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
    
    @ViewBuilder
    private func ReactBtnLableBuilder(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.accentColor)
            .frame(width: 68, height: 48)
            .background(.gray.opacity(0.15), in: .rect(cornerRadius: 12))
    }
}

// MARK: - Data Functions
extension BottomSheetView {
    private func getLocationDetails(address: String?, location: GeoPoint?, pin: String) -> String {
        var result = "Pin: \(pin)\n\n"
        if let address = address {
            result += address
        }
        if let location = location {
            result += "\n\nCoordinates: \(location.toString())"
        }
        return result
    }

    private func getCurrentLocationDetails(pin: String) -> String {
        getLocationDetails(
            address: mapController.addressData.1,
            location: mapController.mapCenter,
            pin: pin
        )
    }

    private func getSearchLocationDetails(pin: String) -> String {
        getLocationDetails(
            address: mapController.searchAddressData.1,
            location: mapController.searchLocation,
            pin: pin
        )
    }
}


// MARK: - View Functions
extension BottomSheetView {
    private func handleFocusChange(old: Bool, new: Bool) {
        if new {
            viewModel.sheetDetent = .fraction(0.999)
//            searchText = "39J-49L-KM47"
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
}

#Preview {
    @Previewable @State var container: ModelContainer = {
        let container = try! ModelContainer(for: DPItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        // Add sample data
        let sampleDPItems = [
            DPItem(pin: "XXX-XXX-XXXX", latitude: 0, longitude: 0),
            DPItem(pin: "YYY-YYY-YYYY", latitude: 0, longitude: 0),
            DPItem(pin: "ZZZ-ZZZ-ZZZZ", latitude: 0, longitude: 0),
            DPItem(pin: "AAA-AAA-AAAA", latitude: 0, longitude: 0)
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
