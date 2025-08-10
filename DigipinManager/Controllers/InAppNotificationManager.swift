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
    
    func copiedToClipboardToast() {
        showToast(title: "Copied to clipboard")
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
    
    @discardableResult
    func showCoordsToPinConverter() -> UUID {
        Task { @MainActor in
            SpeechManager.shared.stop()
        }
        let openConverter = notificationQueue.first(where: { $0.mode == .coordsToPinConverter })
        
        guard openConverter == nil else { return openConverter!.id }
        
        let id = UUID()
        let notification = InAppNotification(
            id: id,
            title: nil,
            message: nil,
            type: .neutral,
            mode: .coordsToPinConverter,
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
    case coordsToPinConverter
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

#Preview {
    ContentView()
        .environmentObject(AppController.shared)
        .environmentObject(MapController.shared)
        .environmentObject(MapViewModel.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(InAppNotificationManager.shared)
}
