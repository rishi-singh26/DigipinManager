//
//  MapViewModel.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI

class MapViewModel: ObservableObject {
    static let shared = MapViewModel()
    
    let lowDetent: PresentationDetent = .height(80)
    let midDetent: PresentationDetent = .height(350)
    let highDetent: PresentationDetent = .fraction(0.999)
    let detents: Set<PresentationDetent> = [.height(80), .height(350), .fraction(0.999)]
    
    @Published var showBottomSheet: Bool = false
    @Published var sheetDetent: PresentationDetent = .height(80)
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
}
