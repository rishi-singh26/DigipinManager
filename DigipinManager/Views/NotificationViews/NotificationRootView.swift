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
                    rootController.view.frame = window.bounds
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
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view else { return nil }

        if #available(iOS 26.0, *) {
            // On iOS 26 the SwiftUI hierarchy is opaque to UIKit: the hosting view no
            // longer exposes its content as hit-testable subviews, so the subview loop
            // below finds nothing and every touch would fall through to the window
            // beneath. The rendered notification content still exists in the layer
            // tree, so decide pass-through from CALayer hit testing instead: a hit on
            // the hosting view's own layer means the touch landed on an empty area.
            let hitLayer = rootView.layer.hitTest(point)
            if hitLayer == nil || hitLayer === rootView.layer {
                return nil
            }
            // Touch is over notification content. Return the view UIKit resolved so
            // the hosting view's gesture system handles the interaction.
            return hitView
        } else {
            // iOS 18: check each subview in the overlay from front to back
            for subview in rootView.subviews.reversed() {
                let pointInSubview = subview.convert(point, from: rootView)
                if let hitSubview = subview.hitTest(pointInSubview, with: event) {
                    return hitSubview
                }
            }

            // No overlay view hit → allow touch to pass to underlying content
            return nil
        }
    }
}
