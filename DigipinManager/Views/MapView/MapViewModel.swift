//
//  MapViewModel.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI

class MapViewModel: ObservableObject {
    static let shared = MapViewModel()
    static let sheetMidHeight: CGFloat = 370
    
    static let lowDetent: CGFloat = 75
    static let midDetent: CGFloat = 0.45
    static let largeScreenHighDetent: CGFloat = 0.97
    
    @Published var showBottomSheet: Bool = false
    @Published var isLargeScreen: Bool = false
    @Published var sheetDetent: PresentationDetent = .height(MapViewModel.lowDetent)
    @Published var sheetHeight: CGFloat = 0
    @Published var animationDuration: CGFloat = 0
    @Published var toolbarOpacity: CGFloat = 1
    @Published var safeAreaBottomInset: CGFloat = 0
    
    
    /// Tracks if the search box is shown
    @Published var showSearchBar: Bool = false
    /// Search text
    @Published var searchText: String = ""
    /// Id of marker selected on map
    @Published var selectedMarker: String?
    
    @Published var mapStylePickerProgress: CGFloat = 0
    @Published var mapStylePcikerAnimation: Animation = .bouncy(duration: 0.4, extraBounce: 0.01)
    
    private init() {}
    
    
    var detents: Set<PresentationDetent> {
        if isLargeScreen {
            return [.height(MapViewModel.lowDetent), .fraction(MapViewModel.largeScreenHighDetent)]
        }
        return [.height(MapViewModel.lowDetent), .fraction(MapViewModel.midDetent), .large]
    }
    
    var cornerRadius: CGFloat? {
        if isLargeScreen {
            return 30
        }
        return nil
    }
    
    func toggleBttomSheet(value: Bool) {
        withAnimation {
            showBottomSheet = value
        }
    }
    
    func dismissMapStylePicker() {
        guard mapStylePickerProgress > 0 else { return }
        
        withAnimation(mapStylePcikerAnimation) {
            mapStylePickerProgress = 0
        }
    }
    
    func handleScreenResize(with newValue: Bool) {
        // Update Detents before any changes!
        if sheetDetent != .height(MapViewModel.lowDetent) && newValue {
            sheetDetent = .fraction(MapViewModel.largeScreenHighDetent)
        } else if sheetDetent == .fraction(MapViewModel.largeScreenHighDetent) && !newValue {
            sheetDetent = .fraction(MapViewModel.midDetent)
        } else {
            sheetDetent = .height(MapViewModel.lowDetent)
        }
        
        isLargeScreen = newValue
    }
}
