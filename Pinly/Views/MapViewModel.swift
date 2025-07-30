//
//  MapViewModel.swift
//  Pinly
//
//  Created by Rishi Singh on 30/07/25.
//

import SwiftUI

class MapViewModel: ObservableObject {
    static let shared = MapViewModel()
    
    @Published var showBottomSheet: Bool = false
    @Published var sheetDetent: PresentationDetent = .height(80)
    @Published var sheetHeight: CGFloat = 0
    @Published var animationDuration: CGFloat = 0
    @Published var toolbarOpacity: CGFloat = 1
    @Published var safeAreaBottomInset: CGFloat = 0
}
