//
//  MarkdownWebView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 06/08/25.
//

import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct MarkdownWebView: View {
    @Environment(\.dismiss) private var dismiss

    let url: URL

    @State private var markdownContent: String?
    @State private var htmlContent: String?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showingFileExporter = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let html = htmlContent {
                WebViewRepresentable(htmlContent: html)
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Error loading content")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Content not found")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let markdownContent = markdownContent, !markdownContent.isEmpty {
                    Button("Export") {
                        exportMarkdown()
                    }
                } else {
                    EmptyView()
                }
            }
        }
        .onAppear {
            loadMarkdown()
        }
        .fileExporter(
            isPresented: $showingFileExporter,
            document: MarkdownDocument(markdownContent ?? ""),
            contentType: .plainText,
            defaultFilename: url.lastPathComponent.replacingOccurrences(of: ".md", with: "") + ".md"
        ) { result in
            switch result {
            case .success(let url):
                print("Exported to \(url)")
            case .failure(let error):
                print("Export error: \(error)")
            }
        }
    }

    private func loadMarkdown() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                guard let markdown = String(data: data, encoding: .utf8) else {
                    throw NSError(domain: "MarkdownWebView", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to decode text content"])
                }
                
                self.markdownContent = markdown
                self.htmlContent = await MarkdownToHtml.convertMarkdownAsync(markdown)
            } catch {
                self.error = error
            }
            
            self.isLoading = false
        }
    }

    
    private func exportMarkdown() {
        showingFileExporter = true
    }
    
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        return MarkdownToHtml.getStyledHTML(MarkdownToHtml.convertToHTML(markdown))
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = [.link, .phoneNumber]
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    static var writableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(_ text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    if let url = URL(string: "https://raw.githubusercontent.com/rishi-singh26/DigipinManager/refs/heads/main/privacy-policy.md") {
        MarkdownWebView(url: url)
    } else {
        Text("Invalid URL")
    }
}
