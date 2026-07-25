//
//  MapViewModel.swift
//  DigipinManager
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI

class MapViewModel: ObservableObject {
    static let shared = MapViewModel()
    static let sheetMidHeight: CGFloat = 318
    
    @Published var showBottomSheet: Bool = false
    @Published var isLargeScreen: Bool = false
    @Published var sheetDetent: PresentationDetent = .height(73)
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
            return [.height(73), .fraction(0.97)]
        }
        return [.height(73), .fraction(0.45), .fraction(0.98)]
    }
    
    var cornerRadius: CGFloat? {
        if isLargeScreen {
            return 35
        }
        return nil
    }
    
    func toggleBttomSheet(value: Bool) {
        withAnimation {
            showBottomSheet = value
        }
    }
}
