//
//  PrivacyPolicyView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 04/08/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        Group {
            if let url = URL(string: "https://raw.githubusercontent.com/rishi-singh26/DigipinManager/refs/heads/main/privacy-policy.md") {
                MarkdownWebView(url: url)
            } else {
                Text("Invalid URL")
            }
        }
        .navigationTitle("Privacy Policy")
    }
}

#Preview {
    PrivacyPolicyView()
}
