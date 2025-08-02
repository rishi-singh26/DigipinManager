//
//  DigipinQRView.swift
//  Pinly
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
                Button{
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical)
            .padding(.horizontal, 20)
            
            QRCodeView(inputText: pin, titleText: pin)
            
            Spacer()
        }
        .presentationDetents([.fraction(0.65)])
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
