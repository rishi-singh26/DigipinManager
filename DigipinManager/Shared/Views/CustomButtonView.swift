//
//  CustomButtonView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 01/08/25.
//

import SwiftUI

struct CButton {
    
    @ViewBuilder
    static func RoundBtn(symbol: String, helpText: String = "", action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            CButton.RoundBtnLabel(symbol: symbol)
        }
        .help(helpText)
    }
    
    @ViewBuilder
    static func RoundBtnLabel(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(width: 48, height: 48)
            .background(.gray.opacity(0.15), in: .circle)
        //.glassEffect(in: .circle)
            .transition(.blurReplace)
    }
    
    @ViewBuilder
    static func RectBtn(symbol: String, helpText: String = "", action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            CButton.RectBtnLabel(symbol: symbol)
        }
        .help(helpText)
    }
    
    @ViewBuilder
    static func RectBtnLabel(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.accentColor)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(.gray.opacity(0.15), in: .rect(cornerRadius: 12))
    }
    
    @ViewBuilder
    static func XMarkBtn(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .padding(8)
                .background(.thinMaterial, in: .circle)
        }
    }
    
    @ViewBuilder
    static func XMarkFillBtn(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    VStack {
        CButton.RectBtn(symbol: "xmark") {
            print("xmark")
        }
        
        CButton.RoundBtn(symbol: "xmark") {
            print("xmark")
        }
    }
}
