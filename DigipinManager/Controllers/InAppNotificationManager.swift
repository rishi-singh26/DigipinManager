//
//  InAppNotificationManager.swift
//  DigipinManager
//
//  Created by Rishi Singh on 02/08/25.
//

import SwiftUI

// MARK: - Notification Manager
class InAppNotificationManager: ObservableObject {
    static let shared = InAppNotificationManager()
    
    @Published var notificationQueue: [InAppNotification] = []
    
    private init() {}
    
    // Show in-app notification
    func showNotification(
        title: String,
        message: String,
        type: NotificationType = .info,
        timing: NotificationTime = .medium
    ) {
        let notification = InAppNotification(
            title: title,
            message: message,
            type: type,
            mode: .notification,
            timing: timing
        )
        
        // Add to queue
        notificationQueue.append(notification)
    }
    
    func showToast(
        title: String,
        type: NotificationType = .info,
        timing: NotificationTime = .medium
    ) {
        let notification = InAppNotification(
            title: nil,
            message: title,
            type: type,
            mode: .toast,
            timing: timing
        )
        
        // Add to queue
        notificationQueue.append(notification)
    }
    
    @discardableResult
    func showAudioController(title: String) -> UUID {
        Task { @MainActor in
            SpeechManager.shared.stop()
        }
        notificationQueue.removeAll(where: { $0.mode == .audioContoll })
        let id = UUID()
        let notification = InAppNotification(
            id: id,
            title: title,
            message: nil,
            type: .neutral,
            mode: .audioContoll,
            timing: .long
        )
        
        // Add to queue
        notificationQueue.append(notification)
        return id
    }
    
    // Clear all notifications (current and queued)
    func clearAllNotifications() {
        notificationQueue.removeAll()
    }
    
    // Get queue count for debugging/UI purposes
    var queueCount: Int {
        return notificationQueue.count
    }
    
    func removeNotification(_ id: UUID) {
        guard let index = notificationQueue.firstIndex(where: { $0.id == id}) else { return }
        notificationQueue[index].isDeleting = true
        
        withAnimation(.bouncy) {
            let _ = notificationQueue.remove(at: index)
        }
    }
    
    func simpleRemoveNotification(_ id: UUID) {
        withAnimation(.bouncy) {
            notificationQueue.removeAll(where: { $0.id == id})
        }
    }
}

// MARK: - Notification Models
struct InAppNotification: Identifiable, Equatable {
    var id: UUID = UUID()
    let title: String?
    let message: String?
    let type: NotificationType
    let mode: NotificationMode
    // Timing
    var timing: NotificationTime = .medium
    
    // View properties
    var offsetX: CGFloat = 0
    var isDeleting: Bool = false
}

enum NotificationMode {
    case notification
    case toast
    case audioContoll
}

enum NotificationTime: CGFloat {
    case short = 1.0
    case medium = 2.0
    case long = 3.5
}

enum NotificationType {
    case success
    case error
    case warning
    case info
    case neutral
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        case .neutral: return .clear
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .neutral: return "square"
        }
    }
}

struct InAppNotificationSelector: View {
    let notification: InAppNotification
    let index: Int
    
    var body: some View {
        Group {
            switch notification.mode {
            case .notification:
                InAppNotificationView(notification: notification, index: index)
            case .toast:
                InAppToastView(notification: notification, index: index)
            case .audioContoll:
                AudioControlNotificationView(notification: notification, index: index)
            }
        }
    }
}

// MARK: - Notification Container
struct NotificationContainer: View {
    @EnvironmentObject private var notificationManager:  InAppNotificationManager
    @State private var isExpanded: Bool = true
    
    var body: some View {
        ZStack(alignment: .top) {
            let layout: AnyLayout = isExpanded ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(ZStackLayout())
            
            // Get the notifications in the correct order based on expansion state
            let notifications = isExpanded ? notificationManager.notificationQueue.reversed() : notificationManager.notificationQueue
            
            layout {
                ForEach(Array(notifications.enumerated()), id: \.element.id) { enumIndex, notification in
                    // For ZStack (collapsed): use original index calculation for stacking effect
                    // For VStack (expanded): enumIndex is already correct (0 = top)
                    let stackIndex = isExpanded ? 0 : (notifications.count - 1 - enumIndex)
                    
                    // Calculate zIndex based on original queue position to maintain consistent layering
                    let originalIndex = notificationManager.notificationQueue.firstIndex(where: { $0.id == notification.id }) ?? 0
                    let baseZIndex = Double(notificationManager.notificationQueue.count - originalIndex)
                    
                    InAppNotificationSelector(notification: notification, index: originalIndex)
                    .offset(x: notification.offsetX)
                    .visualEffect { [isExpanded] content, proxy in
                        content
                            .scaleEffect(isExpanded ? 1 : scale(stackIndex), anchor: .top)
                            .offset(y: isExpanded ? 0 : offsetY(stackIndex))
                    }
                    .zIndex(notification.isDeleting ? 1000 : 1000 - baseZIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .leading)
                    ))
                }
            }
            .onTapGesture {
                isExpanded.toggle()
            }
        }
        .animation(.bouncy, value: isExpanded)
        .animation(.spring(), value: notificationManager.notificationQueue)
        .onChange(of: notificationManager.notificationQueue.isEmpty) { oldValue, newValue in
            if newValue {
                isExpanded = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    nonisolated func offsetY(_ index: Int) -> CGFloat {
        let offset = min(CGFloat(index) * 15, 30)
        return offset
    }
    
    nonisolated func scale(_ index: Int) -> CGFloat {
        let scale = min(CGFloat(index) * 0.1, 1)
        return 1 - scale
    }
}

struct DismissButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.gray)
        }
        .accessibilityLabel("Dismiss notification")
    }
}

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
                        rootView: NotificationContainer().environmentObject(InAppNotificationManager.shared)
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

#Preview {
    ContentView()
        .environmentObject(AppController.shared)
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(InAppNotificationManager.shared)
}
