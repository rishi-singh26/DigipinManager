//
//  NoInternetView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 02/08/25.
//

import SwiftUI

struct NoInternetView: View {
    @Environment(\.isNetworkConnected) private var isConnected
    @Environment(\.connectionType) private var connectionType
    
    let sheetHeight: CGFloat = 400
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 80, weight: .semibold))
                .frame(height: 100)
            
            Text("No Internet Connectivity")
                .font(.title3)
            
            Text("Please check your internet connection.\n\nMap interation has been disabled however you can still search for DIGIPINs and get coordinates.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
            
            Text("Waiting for internet connection...")
                .font(.caption)
                .foregroundStyle(.background)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.primary)
                .padding(.top, 10)
                .padding(.horizontal, -20)
        }
        .fontDesign(.rounded)
        .padding([.horizontal, .top], 20)
        .background(.background)
        .clipShape(.rect(cornerRadius: 20))
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .frame(height: sheetHeight)
        // Sheet modifiers
        .presentationDetents([.height(sheetHeight)])
        .presentationCornerRadius(0)
        .presentationBackgroundInteraction(.disabled)
        .presentationBackground(.clear)
    }
}

#Preview {
    @Previewable @State var showNoInternetSheet: Bool = false
    
    List {
        Button("Show No Internet Sheet") {
            showNoInternetSheet = true
        }
    }.sheet(isPresented: $showNoInternetSheet) {
        NoInternetView()
    }
}
