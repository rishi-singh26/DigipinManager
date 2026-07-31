//
//  MapViewModel.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI

class MapViewModel: ObservableObject {
    static let shared = MapViewModel()
    static let sheetMidHeight: CGFloat = 360
    
    static let lowDetent: CGFloat = 75
    static let midDetent: CGFloat = 0.45
    static let highDetent: CGFloat = 0.98
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
    
    private init() {}
    
    
    var detents: Set<PresentationDetent> {
        if isLargeScreen {
            return [.height(MapViewModel.lowDetent), .fraction(MapViewModel.largeScreenHighDetent)]
        }
        return [.height(MapViewModel.lowDetent), .fraction(MapViewModel.midDetent), .fraction(MapViewModel.highDetent)]
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
}
