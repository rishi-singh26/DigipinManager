//
//  AboutView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 03/08/25.
//

import SwiftUI
import StoreKit

struct AboutView: View {
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
                .buttonStyle(.plain)
                .help("Open help and feedback form in web browser")
                Button {
                        getRating()
                } label: {
                    Label("Rate Us", systemImage: "star")
                }
                .buttonStyle(.plain)
                .help("Give star rating to Digipin Manager")
                Button {
                        openAppStoreReviewPage()
                } label: {
                    CustomLabel(leadingImageName: "quote.bubble", trailingImageName: "arrow.up.right", title: "Write Review on App Store")
                }
                .buttonStyle(.plain)
                .help("Write feedback for Digipin Manager on AppStore")
            }
            
            Section {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Privacy Policy", systemImage: "lock.shield")
                }
            }
            
            Section {
                Button {
                    getConfirmation(url: "https://github.com/rishi-singh26/DigipinManager")
                } label: {
                    CustomLabel(leadingImageName: "lock.open.display", trailingImageName: "arrow.up.right", title: "Source Code - Github")
                }
                .buttonStyle(.plain)
                .help("Open Digipin Manager source code in browser")
                Button {
                    getConfirmation(url: "https://github.com/rishi-singh26/DigipinManager/blob/main/LICENSE")
                } label: {
                    CustomLabel(leadingImageName: "checkmark.seal.text.page", trailingImageName: "arrow.up.right", title: "MIT License")
                }
                .buttonStyle(.plain)
                .help("Open Digipin Manager Open-Source license in browser")
            }
            
            Section {
                Text("Digipin Manager is lovingly developed in India. 🇮🇳")
                    .font(.caption)
            }
        }
        .withURLConfirmation($showURLConfirmation, url: selectedURLForConfirmation ?? "")
    }
    
    private func openAppStoreReviewPage() {
        let urlStr = "https://itunes.apple.com/app/id\(KAppId)?action=write-review"
        
        guard let url = URL(string: urlStr) else { return }
        url.open()
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
