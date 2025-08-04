//
//  AppController.swift
//  DigipinManager
//
//  Created by Rishi Singh on 04/08/25.
//

import SwiftUI

class AppController: ObservableObject {
    static let shared = AppController()
    // Onboarding view state
    @AppStorage("seenOnBoardingView") private var seenOnBoardingView: Bool = false
    @Published var showOnboarding: Bool = false
}

extension AppController {
    func prfomrOnbordingCheck() async {
        try? await Task.sleep(for: .seconds(0.2))
        if !self.seenOnBoardingView {
            await MainActor.run {
                self.showOnboarding = true
            }
        }
    }
    func hideOnboardingSheet() {
        seenOnBoardingView = true
        showOnboarding = false
    }
}
