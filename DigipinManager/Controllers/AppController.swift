//
//  AppController.swift
//  DigipinManager
//
//  Created by Rishi Singh on 04/08/25.
//

import SwiftUI
import MapKit

class AppController: ObservableObject {
    static let shared = AppController()
    // Onboarding view state
    @AppStorage("seenOnBoardingView") private var seenOnBoardingView: Bool = false
    @Published var showOnboarding: Bool = false
    
    /// When searching for a DIGIPIN, on successful search the coordinates are saved to this
    @Published private(set) var searchLocation: CLLocationCoordinate2D?
    /// AddressSearchResult data for searched DIFIPIN
    @Published var searchAddressData: (AddressSearchResult?, String?)
}

// MARK: - Search functionality
extension AppController {
    func closeSearch() {
        withAnimation {
            searchLocation = nil
            searchAddressData = (nil, nil)
        }
    }
    
    func updateSearchLocation(with location: CLLocationCoordinate2D?) {
        withAnimation {
            searchLocation = location
        }
    }
    
    func updateSearchLocation(with location: Coordinate) {
        updateSearchLocation(with: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
    }
}

extension AppController {
    func prfomrOnbordingCheck() async {
        try? await Task.sleep(for: .seconds(0.2))
        if !self.seenOnBoardingView {
            await MainActor.run {
                self.showOnboarding = true
            }
        } else {
            CopyToClipboardTip.show = true // start showing tips if user has already seen onboarding view
        }
    }
    func hideOnboardingSheet() {
        seenOnBoardingView = true
        showOnboarding = false
        
        CopyToClipboardTip.show = true  // start showing tips after user continues from onboarding view
    }
}
