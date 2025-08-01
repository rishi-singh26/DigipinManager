//
//  QRCodeView.swift
//  Pinly
//
//  Created by Rishi Singh on 01/08/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

struct ShareableImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { shareable in
            shareable.image.pngData() ?? Data()
        }
    }
}

import SwiftUI
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

struct QRCodeView: View {
    @Environment(\.colorScheme) var colorScheme
    var inputText: String = "Hello, QR Code!"
    var headerText: String?
    var footerText: String?
    
    @State private var qrImage: UIImage? = nil
    @State private var shareImage: UIImage? = nil

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        VStack(spacing: 20) {
            qrCard
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: inputText) { _, _ in
                                updateShareImage(size: proxy.size)
                            }
                            .onChange(of: colorScheme) { _, _ in
                                updateShareImage(size: proxy.size)
                            }
                            .onAppear {
                                updateShareImage(size: proxy.size)
                            }
                    }
                )

            if let shareImage {
                ShareLink(item: ShareableImage(image: shareImage), preview: SharePreview("QR Code", image: Image(uiImage: shareImage))) {
                    Label("Share QR Code Image", systemImage: "square.and.arrow.up")
                }
            }
        }
        .padding()
    }

    var qrCard: some View {
        VStack(spacing: 10) {
            if let hText = headerText {
                Text(hText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1, reservesSpace: false)
            }

            if let qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(4)
                    .cornerRadius(20)
            }

            if let fText = footerText {
                Text(fText)
                    .multilineTextAlignment(.center)
                    .lineLimit(1, reservesSpace: false)
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
        )
    }

    func updateShareImage(size: CGSize) {
        qrImage = generateQRCode(from: inputText, isDarkMode: colorScheme == .dark)
        shareImage = qrCard.snapshot(size: size)
    }

    func generateQRCode(from string: String, isDarkMode: Bool) -> UIImage? {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        guard let outputImage = filter.outputImage else { return nil }

        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = outputImage
        colorFilter.color0 = CIColor(color: isDarkMode ? .white : .black)
        colorFilter.color1 = CIColor(color: isDarkMode ? .black : .white)

        guard let coloredImage = colorFilter.outputImage else { return nil }

        let scaledImage = coloredImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgimg)
        }

        return nil
    }
}


struct BackgroundRenderer: ViewModifier {
    @Binding var renderedImage: UIImage?

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            render(view: content, size: geo.size)
                        }
                        .onChange(of: geo.size) { _, _ in
                            render(view: content, size: geo.size)
                        }
                }
            )
    }

    private func render<V: View>(view: V, size: CGSize) {
        let controller = UIHostingController(rootView: view.frame(width: size.width, height: size.height))
        let targetSize = controller.view.intrinsicContentSize

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { ctx in
            controller.view.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }

        DispatchQueue.main.async {
            self.renderedImage = image
        }
    }
}

extension View {
    func backgroundRenderer(to image: Binding<UIImage?>) -> some View {
        self.modifier(BackgroundRenderer(renderedImage: image))
    }
    
    func snapshot(size: CGSize) -> UIImage {
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? UIImage()
    }
}


#Preview {
    QRCodeView(inputText: "Hello")
}
