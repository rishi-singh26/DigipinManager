//
//  CoordinateToPinNotificationView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 10/08/25.
//

import SwiftUI
import MapKit

struct CoordinateToPinNotificationView: View {
    @Environment(\.isNetworkConnected) private var isConnected
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var notificationManager: InAppNotificationManager
    @EnvironmentObject private var mapController: MapController
    @EnvironmentObject private var mapViewModel: MapViewModel
    
    enum Field {
        case latitude
        case longitude
    }

    let notification: InAppNotification
    let index: Int
    
    @StateObject private var viewModel = CoordinateToPinNotificationViewModel.shared
    @FocusState private var focusedField: Field?
    
    var body: some View {
        VStack(alignment: .leading) {
            CardBuilder()
        }
        .background {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 50, x: -3, y: -3)
                .shadow(color: .black.opacity(0.2), radius: 50, x: 3, y: 3)
        }
        .contentShape(.rect(cornerRadius: 40))
        .padding(.horizontal, 10)
        .onChange(of: viewModel.location ?? CLLocationCoordinate2D(), { _, newValue in
            // Update map position when the location for provided coordinates is available
            if newValue.latitude != 0.0 && newValue.longitude != 0.0 {
                mapController.updatedMapPosition(with: newValue)
            }
        })
        .onAppear {
            mapViewModel.toggleBttomSheet(value: false)
        }
    }
}


// MARK: - View builders
extension CoordinateToPinNotificationView {
    @ViewBuilder
    private func CardBuilder() -> some View {
        VStack {
            HStack {
                Text("Coordinates to DIGIPIN")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                CButton.XMarkFillBtn(action: removeNotification)
            }
            
            HStack {
                CoordInputBuilder("Latitide", text: $viewModel.latitude, field: .latitude)
                CoordInputBuilder("Longitude", text: $viewModel.longitude, field: .longitude)
            }
            
            if let errMess = viewModel.errorMessage {
                Text(errMess)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(.red.opacity(0.1), in: .rect(cornerRadius: 15))
            }
            
            if viewModel.output.count > 10 {
                OutputBuilder()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func CoordInputBuilder(_ title: String, text: Binding<String>, field: Field) -> some View {
        TextField(title, text: text)
            .focused($focusedField, equals: field)
            .font(.headline)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.background.opacity(0.4), in: .rect(cornerRadius: 16))
            .keyboardType(.numbersAndPunctuation)
            .submitLabel(field == .latitude ? .next : .done)
            .onSubmit {
                if field == .latitude {
                    focusedField = .longitude
                } else if field == .longitude {
                    viewModel.convert()
                }
            }
            .onChange(of: text.wrappedValue) { oldValue, newValue in
                if newValue.isEmpty { return }
                if Double(newValue) == nil {
                    text.wrappedValue = oldValue
                }
            }
    }
    
    @ViewBuilder
    private func OutputBuilder() -> some View {
        VStack(alignment: .leading) {
            Text(viewModel.output.uppercased())
                .textSelection(.enabled)
                .font(.title3)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .contentTransition(.numericText())
            
            Divider()
            
            if let address = viewModel.addressData?.1, address.count > 0 {
                Text(address)
                    .textSelection(.enabled)
                Divider()
            }
            
            HStack {
                ShareLink(item: String.createSharePinData(
                    address: viewModel.addressData?.1 ?? "",
                    location: viewModel.location,
                    pin: viewModel.output
                )) {
                    CButton.RectBtnLabel(symbol: "square.and.arrow.up")
                }
                
                Spacer()
                
                CButton.RectBtn(symbol: "speaker.wave.2", helpText: "Speak DIGIPIN aloud", action: handleSpeech)
                    .buttonStyle(.plain)
                
                Spacer()
                
                CButton.RectBtn(symbol: "document.on.document", helpText: "Copy DIGIPIN") {
                    focusedField = nil
                    notificationManager.copiedToClipboardToast()
                    viewModel.output.uppercased().copyToClipboard()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                CButton.RectBtn(symbol: "pin", helpText: "Add DIGIPIN to pinned list", action: saveSearchedPin)
                    .disabled(viewModel.addressData?.1 == nil)
                    .buttonStyle(.plain)
                
                Spacer()
                
                CButton.RectBtn(symbol: "arrow.trianglehead.turn.up.right.diamond", helpText: "Fly to DIGIPIN location") {
                    mapController.updatedMapPosition(with: viewModel.location!)
                }
                .buttonStyle(.plain)
            }

        }
        .padding()
        .background(.background.opacity(0.4), in: .rect(cornerRadius: 25))
    }
    
    @ViewBuilder
    private func ActionBuilder(
        _ title: String,
        action: @escaping () -> Void,
        foregroundColor: Color,
        backgroundColor: Color
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(foregroundColor)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(backgroundColor, in: .capsule)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Private methods
extension CoordinateToPinNotificationView {
    private func saveSearchedPin() {
        guard let location = viewModel.location else { return }
        guard let address = viewModel.addressData?.1 else { return }
        let (status, message) = mapController.saveToPinnedListIfNotExist(
            pin: viewModel.output,
            address: address,
            coords: Coordinate(latitude: location.latitude, longitude: location.longitude),
            modelContext
        )
        if status {
            notificationManager.showToast(title: "Added to pinned list")
        } else if let message {
            notificationManager.showToast(title: message, type: .warning)
        }
    }
    
    private func removeNotification() {
        focusedField = nil
        SpeechManager.shared.stop()
        mapViewModel.toggleBttomSheet(value: true)
        notificationManager.removeNotification(notification.id)
    }
    
    private func handleSpeech() {
        guard viewModel.output.count > 10 else { return }
        focusedField = nil
        let _ = notificationManager.showAudioController(title: viewModel.output)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppController.shared)
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(InAppNotificationManager.shared)
}
