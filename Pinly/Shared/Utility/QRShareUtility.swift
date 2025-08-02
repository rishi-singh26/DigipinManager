//
//  QRShareUtility.swift
//  Pinly
//
//  Created by Rishi Singh on 01/08/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

class QRShareUtility {
    
    private static let context = CIContext()
    private static let filter = CIFilter.qrCodeGenerator()
    
    /// Generates a QR code with title and subtitle text
    /// - Parameters:
    ///   - inputText: The text to encode in the QR code
    ///   - titleText: Text to display above the QR code
    ///   - subTitleText: Text to display below the QR code
    ///   - isDarkMode: Boolean, decides the appearance of QRCode
    /// - Returns: UIImage containing the QR code with text, or nil if generation fails
    static func generateQRCodeImage(inputText: String, titleText: String, subTitleText: String, isDarkMode: Bool = false) -> UIImage? {
        guard let qrImage = generateQRCode(from: inputText, isDarkMode: isDarkMode) else {
            print("Failed to generate QR code")
            return nil
        }
        
        return createCombinedImage(
            qrCode: qrImage,
            titleText: titleText,
            subtitleText: subTitleText,
            isDarkMode: isDarkMode
        )
    }
    
    /// Generates a QR code from string
    /// - Parameters:
    ///   - from: The text to encode in the QR code
    ///   - isDarkMode: Boolean, decides the appearance of QRCode
    /// - Returns: UIImage containing the QR code with text, or nil if generation fails
    static func generateQRCode(from string: String, isDarkMode: Bool = false) -> UIImage? {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        guard let outputImage = filter.outputImage else { return nil }
        // Apply color filter
        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = outputImage
        
        if isDarkMode {
            // White QR code on black background
            colorFilter.color0 = CIColor(color: .white)
            colorFilter.color1 = CIColor(color: .black)
        } else {
            // Black QR code on white background
            colorFilter.color0 = CIColor(color: .black)
            colorFilter.color1 = CIColor(color: .white)
        }
        
        guard let coloredImage = colorFilter.outputImage else { return nil }
        
        // Scale up the image for better quality
        let transformed = coloredImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Add title and subtilte to a UIImage
    /// - Parameters:
    ///   - qrCode: The image to which title and subtitle are to be added
    ///   - titleText: Text to display above the QR code
    ///   - subTitleText: Text to display below the QR code
    ///   - isDarkMode: Boolean, decides the appearance of QRCode
    /// - Returns: UIImage containing the QR code with text, or nil if generation fails
    static func createCombinedImage(qrCode: UIImage, titleText: String?, subtitleText: String?, isDarkMode: Bool = false) -> UIImage? {
        let imageSize = CGSize(width: 300, height: 400)
        let qrSize = CGSize(width: 200, height: 200)
        
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Set background color based on color scheme
            let backgroundColor = isDarkMode ? UIColor.black : UIColor.white
            let textColor = isDarkMode ? UIColor.white : UIColor.black
            
            cgContext.setFillColor(backgroundColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: imageSize))
            
            if let titleText = titleText {
                // Draw title text
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: textColor
                ]
                // Calculate title position and draw
                let titleSize = titleText.size(withAttributes: titleAttributes)
                let titleRect = CGRect(
                    x: (imageSize.width - titleSize.width) / 2,
                    y: 30,
                    width: titleSize.width,
                    height: titleSize.height
                )
                titleText.draw(in: titleRect, withAttributes: titleAttributes)
            }
            
            // Draw QR code
            let qrRect = CGRect(
                x: (imageSize.width - qrSize.width) / 2,
                y: (imageSize.height - qrSize.height) / 2,
                width: qrSize.width,
                height: qrSize.height
            )
            qrCode.draw(in: qrRect)
            
            if let subtitleText = subtitleText {
                // Draw subtitle text
                let subtitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: textColor.withAlphaComponent(0.7)
                ]
                
                let subtitleSize = subtitleText.size(withAttributes: subtitleAttributes)
                let subtitleRect = CGRect(
                    x: (imageSize.width - subtitleSize.width) / 2,
                    y: imageSize.height - 50,
                    width: subtitleSize.width,
                    height: subtitleSize.height
                )
                subtitleText.draw(in: subtitleRect, withAttributes: subtitleAttributes)
            }
        }
    }
}

// MARK: - Transferable Implementation for SwiftUI ShareLink

struct ShareableQRImage: Transferable {
    let image: UIImage
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { shareable in
            shareable.image.pngData() ?? Data()
        }
    }
}

// MARK: - SwiftUI Integration
struct QRShareButton: View {
    let title: String
    let inputText: String
    let titleText: String
    let subTitleText: String
    
    @State private var qrImage: UIImage?
    @State private var isGenerating: Bool = false
    
    var body: some View {
        Group {
            if let image = qrImage {
                ShareLink(
                    item: ShareableQRImage(image: image),
                    preview: SharePreview("QR Code", image: Image(uiImage: image))
                ) {
                    Label(title, systemImage: "qrcode")
                }
            } else {
                Button(action: generateQRCode) {
                    HStack {
                        Label(isGenerating ? "Generating..." : title, systemImage: "qrcode")
                        if isGenerating {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isGenerating)
            }
        }
        .onChange(of: inputText, { oldValue, newValue in
            //print("Change")
            generateQRCode()
        })
        .onAppear {
            //print("Appear")
            if qrImage == nil {
                generateQRCode()
            }
        }
        .onDisappear {
            //print("Disappear")
        }
    }
    
    private func generateQRCode() {
        guard !isGenerating else { return }
        isGenerating = true
        
        // Generate on background queue to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let image = QRShareUtility.generateQRCodeImage(
                inputText: inputText,
                titleText: titleText,
                subTitleText: subTitleText
            )
            
            DispatchQueue.main.async {
                self.qrImage = image
                self.isGenerating = false
            }
        }
    }
}

#Preview {
    NavigationView {
        List {
            Text("QR Code Sharing Demo")
            
            QRShareButton(
                title: "Share QR Code",
                inputText: "https://www.apple.com",
                titleText: "Visit Apple",
                subTitleText: "Scan this code to open Apple's website"
            )
        }
        .navigationTitle("QR Share Utility")
    }
}

