//
//  AboutView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 03/08/25.
//

import SwiftUI
import StoreKit

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    
    @State private var showURLConfirmation: Bool = false
    @State private var selectedURLForConfirmation: String? = nil
    
    var body: some View {
        List {
            HStack {
                Image("PresentationIcon")
                    .resizable()
                    .frame(width: 70, height: 70)
                    .clipShape(.rect(cornerRadius: 15))
                    .padding(.trailing, 15)
                VStack(alignment: .leading) {
                    Text("Digipin Manager")
                        .font(.title.bold())
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                        .font(.callout)
                        .foregroundStyle(.gray)
                    Text("Develoved by Rishi Singh")
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
            }
            
            Section {
                Button {
                    getConfirmation(url: "https://letterbird.co/digipin-manager")
                } label: {
                    CustomLabel(leadingImageName: "text.bubble", trailingImageName: "arrow.up.right", title: "Help & Feedback")
                }
                .help("Open help and feedback form in web browser")
                Button {
//                        getRating()
                } label: {
                    Label("Rate Us", systemImage: "star")
                }
                .help("Give star rating to TempBox")
                Button {
//                        openAppStoreReviewPage()
                } label: {
                    CustomLabel(leadingImageName: "quote.bubble", trailingImageName: "arrow.up.right", title: "Write Review on App Store")
                }
                .help("Write feedback for TempBox on AppStore")
            }
            
            Section {
                Button {
//                        getConfirmation(url: KPrivactPolicyURL)
                } label: {
                    CustomLabel(leadingImageName: "lock.shield", trailingImageName: "arrow.up.right", title: "Privacy Policy")
                }
                .help("Open Digipin Manager privacy policy")
                Button {
//                        getConfirmation(url: KTermsOfServiceURL)
                } label: {
                    CustomLabel(leadingImageName: "list.bullet.rectangle.portrait", trailingImageName: "arrow.up.right", title: "Terms of Service")
                }
                .help("Open Digipin Manager terms of service")
            }
            
            Section {
                Button {
                    getConfirmation(url: "https://github.com/rishi-singh26/TempBox-SwiftUI")
                } label: {
                    CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
                }
                .help("Open Digipin Manager source code in browser")
                Button {
                    getConfirmation(url: "https://github.com/rishi-singh26/TempBox-SwiftUI/blob/main/LICENSE")
                } label: {
                    CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
                }
                .help("Open Digipin Manager Open-Source license in browser")
            }
            
//            Section("Copyright © 2025 Rishi Singh. All Rights Reserved.") {
            Section {
                Button {
                    getConfirmation(url: "https://tempbox.rishisingh.in")
                } label: {
                    CustomLabel(leadingImageName: "network", trailingImageName: "arrow.up.right", title: "https://tempbox.rishisingh.in")
                }
                .help("Visit Digipin Manager website in browser")

                Text("Digipin Manager is lovingly developed in India. 🇮🇳")
                    .font(.caption)
            }
        }
        .alert("Open URL?", isPresented: $showURLConfirmation) {
            Button("Open") {
                guard let urlString = selectedURLForConfirmation else { return }
                guard let url = URL(string: urlString) else { return }
                openURL(url)
            }
            Button("Copy") {
                guard let urlString = selectedURLForConfirmation else { return }
                urlString.copyToClipboard()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you wnat to open this URL?\n\(selectedURLForConfirmation ?? "")")
        }
    }
    
    private func openAppStoreReviewPage() {
        let urlStr = "https://itunes.apple.com/app/id\(KAppId)?action=write-review"
        
        guard let url = URL(string: urlStr) else { return }
        openURL(url)
    }
    
    private func getRating() {
#if os(iOS)
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
#elseif os(macOS)
        SKStoreReviewController.requestReview() // macOS doesn't need a scene
#elseif os(tvOS)
        SKStoreReviewController.requestReview() // tvOS doesn't need a scene
#elseif os(watchOS)
        // watchOS doesn't support SKStoreReviewController
        print("SKStoreReviewController not supported on watchOS")
#endif
    }
    
    private func getConfirmation(url: String) {
        selectedURLForConfirmation = url
        showURLConfirmation = true
    }
}


#Preview {
    AboutView()
}
