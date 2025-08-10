//
//  CoordinateToPinNotificationView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 10/08/25.
//

import SwiftUI
import MapKit

@Observable
fileprivate class Convertor {
    var latitude: String = ""
    var longitude: String = ""
    
    var location: CLLocationCoordinate2D?
    var addressData: (AddressSearchResult?, String?)?
    
    var output: String = ""
    var errorMessage: String?
    
    func convert() {
        guard let lat = Double(latitude) else {
            handleError("Enter valid latitude")
            return
        }
        
        guard let lon = Double(longitude) else {
            handleError("Enter valid longitude")
            return
        }
        
        location = .init(latitude: lat, longitude: lon)
        fetchAddress()
        
        do {
            if let pin = try DigipinUtility.getPinFrom(latitude: lat, longitude: lon) {
                setPin(pin)
            } else {
                handleError("Some thing went wrong!")
            }
        } catch {
            handleError("Coordinates out of bounds!")
        }
    }
    
    func isInValid() -> Bool {
        if Double(latitude) == nil || Double(longitude) == nil {
            return true
        } else {
            return false
        }
    }
    
    private func setPin(_ pin: String) {
        withAnimation {
            output = pin
            errorMessage = nil
        }
    }
    
    private func handleError(_ messaage: String) {
        withAnimation {
            output = ""
            errorMessage = messaage
        }
        addressData = nil
    }
    
    private func fetchAddress() {
        guard let location = location else { return }
        var addressData: (AddressSearchResult?, String?)?
        Task {
            addressData = try? await AddressUtility.shared.getAddressFromLocation(location)
            withAnimation {
                self.addressData = addressData
            }
        }
    }
}

struct CoordinateToPinNotificationView: View {
    @Environment(\.isNetworkConnected) private var isConnected
    
    @EnvironmentObject private var notificationManager: InAppNotificationManager
    @EnvironmentObject private var mapController: MapController
    
    enum Field {
        case latitude
        case longitude
    }

    let notification: InAppNotification
    let index: Int
    
    @State private var convertor = Convertor()
    @FocusState private var focusedField: Field?
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Coordinates to DIGIPIN")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    CButton.XMarkFillBtn(action: removeNotification)
                }
                
                HStack {
                    CoordInputBuilder("Latitide", text: $convertor.latitude, field: .latitude)
                    CoordInputBuilder("Longitude", text: $convertor.longitude, field: .longitude)
                }
                
                if let errMess = convertor.errorMessage {
                    Text(errMess)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(.red.opacity(0.1), in: .rect(cornerRadius: 15))
                }
                
                if convertor.output.count > 10 {
                    OutputBuilder()
                }
                
                HStack {
                    ActionBuilder("Cancel",
                                  action: removeNotification,
                                  foregroundColor: .primary,
                                  backgroundColor: Color.gray.opacity(0.35))
                    Spacer()
                    ActionBuilder("Convert",
                                  action: convertData,
                                  foregroundColor: .white,
                                  backgroundColor: Color.accentColor)
                    .disabled(convertor.isInValid())
                }
                .padding(.top)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 50, x: -3, y: -3)
                .shadow(color: .black.opacity(0.2), radius: 50, x: 3, y: 3)
        }
        .contentShape(.rect(cornerRadius: 40))
        .padding(.horizontal, 10)
    }
    
    @ViewBuilder
    private func CoordInputBuilder(_ title: String, text: Binding<String>, field: Field) -> some View {
        TextField(title, text: text)
            .focused($focusedField, equals: field)
            .font(.headline)
            .padding()
            .background(.background.opacity(0.4), in: .rect(cornerRadius: 25))
            .keyboardType(.numbersAndPunctuation)
            .submitLabel(field == .latitude ? .next : .go)
            .onSubmit {
                if field == .latitude {
                    focusedField = .longitude
                } else if field == .longitude {
                    convertData()
                }
            }
            .onChange(of: text.wrappedValue) { oldValue, newValue in
                if newValue.count == 0 {
                    return
                }
                if Double(newValue) == nil {
                    text.wrappedValue = oldValue
                }
            }
    }
    
    @ViewBuilder
    private func OutputBuilder() -> some View {
        VStack(alignment: .leading) {
            Text(convertor.output.uppercased())
                .font(.title3)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .contentTransition(.numericText())
            
            Divider()
            
            if let address = convertor.addressData?.1, address.count > 0 {
                Text(address)
                Divider()
            }
            
            HStack {
                ShareLink(item: String.createSharePinData(
                    address: convertor.addressData?.1 ?? "",
                    location: convertor.location,
                    pin: convertor.output
                )) {
                    CButton.RectBtnLabel(symbol: "square.and.arrow.up")
                }
                
                Spacer()
                
                CButton.RectBtn(symbol: "document.on.document", helpText: "Copy DIGIPIN") {
                    focusedField = nil
                    notificationManager.copiedToClipboardToast()
                    convertor.output.uppercased().copyToClipboard()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                CButton.RectBtn(symbol: "speaker.wave.2", helpText: "Speak DIGIPIN aloud", action: handleSpeech)
                    .buttonStyle(.plain)
                
                Spacer()
                
                CButton.RectBtn(symbol: "arrow.trianglehead.turn.up.right.diamond", helpText: "Fly to DIGIPIN location") {
                    mapController.updatedMapPosition(with: convertor.location!)
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
    
    private func convertData() {
        focusedField = nil
        convertor.convert()
    }
    
    private func removeNotification() {
        focusedField = nil
        SpeechManager.shared.stop()
        notificationManager.removeNotification(notification.id)
    }
    
    private func handleSpeech() {
        guard convertor.output.count > 10 else { return }
        focusedField = nil
        let _ = notificationManager.showAudioController(title: convertor.output)
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
