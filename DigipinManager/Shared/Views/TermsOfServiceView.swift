//
//  TermsOfServiceView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 13/08/25.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        Group {
            if let url = URL(string: "https://raw.githubusercontent.com/rishi-singh26/DigipinManager/refs/heads/main/terms-of-service.md") {
                MarkdownWebView(url: url)
            } else {
                Text("Invalid URL")
            }
        }
        .navigationTitle("Terms of Service")
    }
}

#Preview {
    TermsOfServiceView()
}
