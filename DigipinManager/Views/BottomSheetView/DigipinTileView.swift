//
//  DigipinTileView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 02/08/25.
//

import SwiftUI
import MapKit
import SwiftData

struct DigipinTileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var mapController: MapController
    
    var address: String
    var location: CLLocationCoordinate2D?
    var pin: String
    var dpItem: DPItem?
    
    var action1: () -> Void
    var action2: (() -> Void)?
    
    init(address: String, location: CLLocationCoordinate2D? = nil, pin: String, action1: @escaping () -> Void, action2: (() -> Void)? = nil) {
        self.address = address
        self.location = location
        self.pin = pin
        self.dpItem = nil
        
        self.action1 = action1
        self.action2 = action2
    }
    
    init(dpItem: DPItem, action1: @escaping () -> Void, action2: (() -> Void)? = nil) {
        self.address = dpItem.address
        self.location = CLLocationCoordinate2D(latitude: dpItem.latitude, longitude: dpItem.longitude)
        self.pin = dpItem.id
        self.dpItem = dpItem
        
        self.action1 = action1
        self.action2 = action2
    }
    
    var body: some View {
        Section {
            if !address.isEmpty {
                Text(address)
                    .lineLimit(2, reservesSpace: true)
                    .textSelection(.enabled)
            }
            //Text(pin)
            //    .textSelection(.enabled)
            LatLonView(location, prefix: "Coordinates: ")
            HStack {
                ShareLink(item: String.createSharePinData(address: address, location: location, pin: pin)) {
                    CButton.RectBtnLabel(symbol: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                CButton.RectBtn(symbol: "qrcode", helpText: "Share DIGIPIN details via QR code", action: action1)
                    .buttonStyle(.plain)
                
                Spacer()
                
                if let action2 = action2 {
                    CButton.RectBtn(symbol: "pin", helpText: "Pin DIGIPIN to list", action: action2)
                        .buttonStyle(.plain)
                } else if let dpItem = dpItem {
                    CButton.RectBtn(symbol: "arrow.trianglehead.turn.up.right.diamond", helpText: "Navigatie to DIGIPIN") {
                        mapController.updatedMapPosition(with: Coordinate(latitude: dpItem.latitude, longitude: dpItem.longitude))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Menu {
                    ShareLink("Share Coordinates", item: location!.toString())
                        .disabled(location == nil)
                    ShareLink("Share DIGIPIN", item: pin)
                    
                    Divider()
                    
                    if let dpItem = dpItem {
                        Button {
                            dpItem.favourite.toggle()
                            try? modelContext.save()
                        } label: {
                            Label("\(dpItem.favourite ? "Remove": "Mark as") Favourite", systemImage: dpItem.favourite ? "star.fill": "star")
                        }
                        .help("\(dpItem.favourite ? "Remove": "Mark as") Favourite")
                    }
                    
                    Divider()
                    
                    Button {
                        address.copyToClipboard()
                    } label: {
                        Label("Copy Address", systemImage: "document.on.document")
                    }
                    .help("Copy address to clipboard")
                    Button {
                        location?.toString().copyToClipboard()
                    } label: {
                        Label("Copy Coordinates", systemImage: "document.on.document")
                    }
                    .disabled(location == nil)
                    .help("Copy coordinates to clipboard")
                    
                    Divider()
                    
                    Button {
                        guard let urlStr = location?.appleMapsURL() else { return }
                        guard let url = URL(string: urlStr) else { return }
                        url.open()
                    } label: {
                        Label("Open in Apple Maps", systemImage: "map")
                    }
                    .disabled(location == nil)
                    .help("Open location in apple maps")
                    Button {
                        guard let urlStr = location?.googleMapsURL() else { return }
                        guard let url = URL(string: urlStr) else { return }
                        url.open()
                    } label: {
                        Label("Open in Google Maps", systemImage: "map")
                    }
                    .disabled(location == nil)
                    .help("Open location in google maps")
                    
                } label: {
                    CButton.RectBtnLabel(symbol: "ellipsis")
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
//    DigipinTileView()
}
