//
//  NotificationRootView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 10/08/25.
//

import SwiftUI

struct NotificationRootView<Content: View>: View {
    @ViewBuilder var content: Content
    // View properties
    @State private var overlayWindow: UIWindow?
    
    var body: some View {
        content
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, overlayWindow == nil {
                    let window = PassthroughWindow(windowScene: windowScene)
                    window.backgroundColor = .clear
                    // View controller
                    let rootController = UIHostingController(
                        rootView: NotificationContainer()
                            .environmentObject(InAppNotificationManager.shared)
                            .environmentObject(MapController.shared)
                            .environmentObject(MapViewModel.shared)
                            .modelContainer(ModelContextContainer.shared.sharedModelContainer)
                    )
                    rootController.view.frame = windowScene.keyWindow?.frame ?? .zero
                    rootController.view.backgroundColor = .clear
                    window.rootViewController = rootController
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    window.tag = 1009
                    
                    overlayWindow = window
                }
            }
    }
}

fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let rootView = rootViewController?.view else { return nil }

        // Check each subview in the overlay from front to back
        for subview in rootView.subviews.reversed() {
            let pointInSubview = subview.convert(point, from: rootView)
            if let hitView = subview.hitTest(pointInSubview, with: event) {
                
                // If the tapped view (or its ancestor) is a UIControl (Button, Toggle, etc.), allow the tap
                if hitView is UIControl || hitView.gestureRecognizers?.isEmpty == false {
                    return hitView
                }
                
                // Otherwise, block it (return something in the overlay so it doesn't fall through)
                return rootView
            }
        }

        // No overlay view hit → allow touch to pass to underlying content
        return nil
    }
}
