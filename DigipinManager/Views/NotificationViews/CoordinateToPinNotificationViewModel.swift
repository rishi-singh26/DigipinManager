//
//  CoordinateToPinNotificationViewModel.swift
//  DigipinManager
//
//  Created by Rishi Singh on 13/08/25.
//

import SwiftUI
import Combine
import MapKit

class CoordinateToPinNotificationViewModel: ObservableObject {
    @Published var latitude: String = ""
    @Published var longitude: String = ""
    
    @Published var location: CLLocationCoordinate2D?
    @Published var addressData: (AddressSearchResult?, String?)?
    
    @Published var output: String = ""
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // To avoid unnecessary updates to address, this debouncer has been setup
        // The address will update 0.5 seconds after user has stopped typing in either latitude or longitude field
        // Conversion happens if the data entered is valid
        // `location` field is updated during the conversion process in the `convert` method
        // In the view, onChange of location, map position is also updated instantly
        setupDebounce()
    }
    
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
    
    func fetchAddress() {
        guard let location = location else { return }
        Task {
            // Run the network or long-running operation off the main thread
            let addressData = try? await AddressUtility.shared.getAddressFromLocation(location)
            
            // Switch to main thread only for UI update
            await MainActor.run {
                withAnimation {
                    self.addressData = addressData
                }
            }
        }
    }
    
    private func setupDebounce() {
        // 1. Immediate conversion on valid inputs
        Publishers.CombineLatest($latitude, $longitude)
            .sink { [weak self] lat, lon in
                guard let self = self else { return }
                
                guard let _ = Double(lat), let _ = Double(lon) else { return }
                
                self.latitude = lat
                self.longitude = lon
                self.convert()
            }
            .store(in: &cancellables)
        
        // 2. Debounced map update after typing stops
        Publishers.CombineLatest($latitude, $longitude)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] lat, lon in
                guard let self = self else { return }
                
                guard let safeLat = Double(lat), let safeLon = Double(lon) else { return }
                
                location = .init(latitude: safeLat, longitude: safeLon)
                fetchAddress()
            }
            .store(in: &cancellables)
    }
}
