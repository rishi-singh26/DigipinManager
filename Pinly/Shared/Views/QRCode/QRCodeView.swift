//
//  QRCodeView.swift
//  Pinly
//
//  Created by Rishi Singh on 01/08/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

struct QRCodeView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var inputText: String
    var titleText: String?
    var subtitleText: String?
    
    @State private var qrImage: UIImage? = nil
    @State private var combinedImage: UIImage? = nil

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        VStack(spacing: 40) {
            if let image = qrImage {
                VStack(spacing: 16) {
                    if let title = titleText {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }
                    
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    if let subTitle = subtitleText {
                        Text(subTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                        .stroke(.gray, lineWidth: 0.2)
                )

                // Share button
                ShareLink(
                    item: ShareableImage(image: combinedImage ?? image),
                    preview: SharePreview(inputText, image: Image(uiImage: combinedImage ?? image))
                ) {
                    Label("Share QR Code", systemImage: "square.and.arrow.up")
                        .padding(.vertical, 10)
                        .padding(.horizontal, 30)
                        .background(.gray.opacity(0.15), in: .rect(cornerRadius: 12))
                }
            } else {
                Text("Unable to generate QR code.")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            generateQRCodeWithText()
        }
        .onChange(of: inputText) { _, newValue in
            generateQRCodeWithText()
        }
        .onChange(of: colorScheme) { _, newValue in
            generateQRCodeWithText()
        }
    }

    func generateQRCodeWithText() {
        let isDarkMode = colorScheme == .dark
        guard let qrCode = QRShareUtility.generateQRCode(from: inputText, isDarkMode: isDarkMode) else { return }
        qrImage = qrCode
        combinedImage = QRShareUtility.createCombinedImage(qrCode: qrCode, titleText: titleText, subtitleText: subtitleText, isDarkMode: isDarkMode)
    }
}

struct ShareableImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) {
            shareable in
            shareable.image.pngData() ?? Data()
        }
    }
}

#Preview {
    QRCodeView(
        inputText: "https://www.apple.com"
    )
}
