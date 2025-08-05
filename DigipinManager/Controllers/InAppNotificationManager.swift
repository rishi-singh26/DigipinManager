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
    let id: UUID = UUID()
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

// MARK: - In-App Notification View
struct InAppNotificationView: View {
    @EnvironmentObject private var notificationManager:  InAppNotificationManager
    @State private var delayTask: DispatchWorkItem?

    let notification: InAppNotification
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        if notification.type != .neutral {
                            Image(systemName: notification.type.icon)
                                .foregroundColor(notification.type.color)
                                .font(.title3)
                        }
                        Text(notification.title ?? "")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    Text(notification.message ?? "")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                DismissButton {
                    if let delayTask {
                        delayTask.cancel()
                    }
                    notificationManager.removeNotification(notification.id)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
                .stroke(.gray, lineWidth: 0.15)
                .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
        }
        .contentShape(.rect(cornerRadius: 14))
        .padding(.horizontal, 10)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let xOffset = value.translation.width < 0 ? value.translation.width : 0
                    notificationManager.notificationQueue[index].offsetX = xOffset
                }.onEnded { value in
                    let xOffset = value.translation.width + (value.velocity.width / 2)
                    
                    if -xOffset > 200 {
                        // Remove notification
                        if let delayTask {
                            delayTask.cancel()
                        }
                        notificationManager.removeNotification(notification.id)
                    } else {
                        // Reset notification position
                        withAnimation(.snappy) {
                            notificationManager.notificationQueue[index].offsetX = 0
                        }
                    }
                }
        )
//        .onAppear {
//            guard delayTask == nil else { return }
//            delayTask = .init(block: {
//                notificationManager.simpleRemoveNotification(notification.id)
//            })
//            
//            if let delayTask {
//                DispatchQueue.main.asyncAfter(deadline: .now() + notification.timing.rawValue, execute: delayTask)
//            }
//        }
    }
}

// MARK: - Toast View
struct InAppToastView: View {
    @EnvironmentObject private var notificationManager:  InAppNotificationManager
    @State private var delayTask: DispatchWorkItem?

    let notification: InAppNotification
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                if notification.type != .neutral {
                    Image(systemName: notification.type.icon)
                        .foregroundColor(notification.type.color)
                        .font(.title2)
                }
                
                Text(notification.message ?? "")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                DismissButton {
                    if let delayTask {
                        delayTask.cancel()
                    }
                    notificationManager.removeNotification(notification.id)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background {
            Capsule()
                .fill(.thinMaterial)
                .stroke(.gray, lineWidth: 0.15)
                .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
        }
        .contentShape(.capsule)
        .padding(.horizontal, 10)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let xOffset = value.translation.width < 0 ? value.translation.width : 0
                    notificationManager.notificationQueue[index].offsetX = xOffset
                }.onEnded { value in
                    let xOffset = value.translation.width + (value.velocity.width / 2)
                    
                    if -xOffset > 200 {
                        // Remove notification
                        if let delayTask {
                            delayTask.cancel()
                        }
                        notificationManager.removeNotification(notification.id)
                    } else {
                        // Reset notification position
                        withAnimation(.snappy) {
                            notificationManager.notificationQueue[index].offsetX = 0
                        }
                    }
                }
        )
        .onAppear {
            guard delayTask == nil else { return }
            delayTask = .init(block: {
                notificationManager.simpleRemoveNotification(notification.id)
            })
            
            if let delayTask {
                DispatchQueue.main.asyncAfter(deadline: .now() + notification.timing.rawValue, execute: delayTask)
            }
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
            }
        }
    }
}

// MARK: - Notification Container
struct NotificationContainer: View {
    @EnvironmentObject private var notificationManager:  InAppNotificationManager
    @State private var isExpanded: Bool = false
    
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
                isExpanded = false
            }
        }
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

private struct DismissButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.gray)
        }
        .accessibilityLabel("Dismiss notification")
    }
}

// MARK: - Extension for Easy Usage
extension View {
    func withInAppNotifications() -> some View {
        self
            .overlay(alignment: .top) {
                NotificationContainer()
            }
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
