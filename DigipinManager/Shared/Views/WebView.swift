////
////  WebView.swift
////  DigipinManager
////
////  Created by Rishi Singh on 03/08/25.
////
//
//import SwiftUI
//import WebKit
//
//struct WebViewRepresentable: UIViewRepresentable {
//    let url: URL
//    @Binding var isLoading: Bool
//    @Binding var webView: WKWebView?
//    
//    func makeUIView(context: Context) -> WKWebView {
//        let webView = WKWebView()
//        webView.navigationDelegate = context.coordinator
//        webView.allowsBackForwardNavigationGestures = true
//        
//        // Load the URL only once when creating the view
//        let request = URLRequest(url: url)
//        webView.load(request)
//        
//        DispatchQueue.main.async {
//            self.webView = webView
//        }
//        
//        return webView
//    }
//    
//    func updateUIView(_ webView: WKWebView, context: Context) {
//        // Don't reload on updates to prevent flickering
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, WKNavigationDelegate {
//        let parent: WebViewRepresentable
//        
//        init(_ parent: WebViewRepresentable) {
//            self.parent = parent
//        }
//        
//        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//            // Allow the initial URL load
//            if navigationAction.request.url == parent.url {
//                decisionHandler(.allow)
//                return
//            }
//            
//            // For any other navigation, show confirmation
//            guard let url = navigationAction.request.url else {
//                decisionHandler(.cancel)
//                return
//            }
//            
//            DispatchQueue.main.async {
//                self.showNavigationConfirmation(for: url) { shouldNavigate in
//                    decisionHandler(shouldNavigate ? .allow : .cancel)
//                }
//            }
//        }
//        
//        private func showNavigationConfirmation(for url: URL, completion: @escaping (Bool) -> Void) {
//            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//                  let window = windowScene.windows.first,
//                  let rootViewController = window.rootViewController else {
//                completion(false)
//                return
//            }
//            
//            let alert = UIAlertController(
//                title: "Open Link",
//                message: "Do you want to navigate to:\n\(url.absoluteString)",
//                preferredStyle: .alert
//            )
//            
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
//                completion(false)
//            })
//            
//            alert.addAction(UIAlertAction(title: "Open", style: .default) { _ in
//                completion(true)
//            })
//            
//            rootViewController.present(alert, animated: true)
//        }
//        
//        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//            DispatchQueue.main.async {
//                self.parent.isLoading = true
//            }
//        }
//        
//        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//            DispatchQueue.main.async {
//                self.parent.isLoading = false
//            }
//        }
//        
//        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//            DispatchQueue.main.async {
//                self.parent.isLoading = false
//            }
//        }
//    }
//}
//
//struct WebViewScreen: View {
//    let url: URL
//    @Environment(\.dismiss) private var dismiss
//    @State private var isLoading = true
//    @State private var webView: WKWebView?
//    
//    var body: some View {
//        NavigationView {
//            WebViewRepresentable(url: url, isLoading: $isLoading, webView: $webView)
//            .navigationTitle(url.host ?? "Web")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//                
//                ToolbarItem(placement: .bottomBar) {
//                    HStack {
//                        Button(action: reloadPage) {
//                            Image(systemName: "arrow.clockwise")
//                        }
//                        .disabled(isLoading)
//                        
//                        Spacer()
//                        
//                        Button(action: openInSafari) {
//                            Image(systemName: "safari")
//                        }
//                        
//                        Spacer()
//                        
//                        Button(action: shareURL) {
//                            Image(systemName: "square.and.arrow.up")
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private func reloadPage() {
//        webView?.reload()
//    }
//    
//    private func openInSafari() {
//        UIApplication.shared.open(url)
//    }
//    
//    private func shareURL() {
//        let activityViewController = UIActivityViewController(
//            activityItems: [url],
//            applicationActivities: nil
//        )
//        
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let window = windowScene.windows.first,
//              let rootViewController = window.rootViewController else {
//            return
//        }
//        
//        // Configure for iPad
//        if let popover = activityViewController.popoverPresentationController {
//            popover.sourceView = window
//            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
//            popover.permittedArrowDirections = []
//        }
//        
//        rootViewController.present(activityViewController, animated: true)
//    }
//}
//
//#Preview {
//    WebViewScreen(url: URL(string: "https://www.apple.com")!)
//}
