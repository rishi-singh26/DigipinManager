//
//  DigipinQRView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 01/08/25.
//

import SwiftUI

struct DigipinQRView: View {
    @Environment(\.dismiss) private var dismiss
    
    let pin: String
    
    var body: some View {
        VStack {
            HStack {
                //Text(pin)
                //    .font(.title3)
                //    .fontWeight(.semibold)
                Spacer()
                CButton.XMarkBtn {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical)
            .padding(.horizontal, 20)
            
            QRCodeView(inputText: pin, titleText: pin, subtitleText: "Scan QR to get DIGIPIN")
            
            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .presentationDetents([.fraction(0.80)])
        .presentationBackgroundInteraction(.enabled)
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    @Previewable @State var showSheet: Bool = false
    
    NavigationView {
        List {
            Button("Show Sheet") {
                showSheet = true
            }
        }
        .onAppear(perform: {
            showSheet = true
        })
        .sheet(isPresented: $showSheet) {
            DigipinQRView(pin: "Hello There")
        }
    }
}
