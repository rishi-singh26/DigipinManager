//
//  InAppNotificationManager.swift
//  DigipinManager
//
//  Created by Rishi Singh on 02/08/25.
//

import SwiftUI
import UserNotifications

// MARK: - App Delegate for Notification Setup
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set the notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        requestNotificationPermission()
        
        return true
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap here
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped with userInfo: \(userInfo)")
        
        // Post notification to update UI if needed
        NotificationCenter.default.post(name: NSNotification.Name("NotificationTapped"), object: userInfo)
        
        completionHandler()
    }
}

// MARK: - Notification Manager
class InAppNotificationManager: ObservableObject {
    @Published var currentNotification: InAppNotification?
    
    private var notificationQueue: [QueuedNotification] = []
    private var dismissTimer: Timer?
    
    static let shared = InAppNotificationManager()
    
    private init() {}
    
    // Show in-app notification
    func showNotification(title: String, message: String, type: NotificationType = .info, duration: TimeInterval = 3.0) {
        let notification = InAppNotification(
            id: UUID(),
            title: title,
            message: message,
            type: type,
            timestamp: Date()
        )
        
        let queuedNotification = QueuedNotification(notification: notification, duration: duration)
        
        // Add to queue
        notificationQueue.append(queuedNotification)
        
        // Show next notification if none is currently displayed
        showNextNotificationIfNeeded()
    }
    
    // Dismiss current notification
    func dismissCurrentNotification() {
        guard currentNotification != nil else { return }
        
        // Cancel any existing timer
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        withAnimation(.spring()) {
            currentNotification = nil
        }
        
        // Show next notification after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showNextNotificationIfNeeded()
        }
    }
    
    // Show next notification from queue
    private func showNextNotificationIfNeeded() {
        // Don't show if there's already a notification displayed
        guard currentNotification == nil, !notificationQueue.isEmpty else { return }
        
        let queuedNotification = notificationQueue.removeFirst()
        
        withAnimation(.spring()) {
            currentNotification = queuedNotification.notification
        }
        
        // Set up auto-dismiss timer
        dismissTimer = Timer.scheduledTimer(withTimeInterval: queuedNotification.duration, repeats: false) { _ in
            self.dismissCurrentNotification()
        }
    }
    
    // Clear all notifications (current and queued)
    func clearAllNotifications() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        notificationQueue.removeAll()
        
        withAnimation(.spring()) {
            currentNotification = nil
        }
    }
    
    // Get queue count for debugging/UI purposes
    var queueCount: Int {
        return notificationQueue.count + (currentNotification != nil ? 1 : 0)
    }
    
    // Send system notification (for background/foreground)
    func sendSystemNotification(title: String, body: String, userInfo: [String: Any] = [:], delay: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 0.1), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

// MARK: - Notification Models
struct InAppNotification: Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
}

struct QueuedNotification {
    let notification: InAppNotification
    let duration: TimeInterval
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
    let notification: InAppNotification
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    private let dismissThreshold: CGFloat = -100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                if notification.type != .neutral {
                    Image(systemName: notification.type.icon)
                        .foregroundColor(notification.type.color)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(notification.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding([.horizontal, .top], 10)
            .frame(maxWidth: .infinity)
            
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary)
                    .frame(width: 40, height: 3)
                    .padding(.top, 8)
                Spacer()
            }
        }
        .padding([.horizontal, .top], 12)
        .padding(.bottom, 6)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(.thinMaterial)
                .stroke(.gray, lineWidth: 0.15)
                .shadow(radius: 20)
        }
        .padding(.horizontal, 10)
        .offset(y: dragOffset)
        .scaleEffect(scale)
        .opacity(opacity)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow upward drag (negative y values)
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                        isDragging = true
                        
                        // Update scale and opacity based on drag distance
                        let dragDistance = abs(value.translation.height)
                        scale = max(0.95, 1.0 - (dragDistance / 1000))
                        opacity = max(0.3, 1.0 - (dragDistance / 300))
                    }
                }
                .onEnded { value in
                    if value.translation.height < dismissThreshold {
                        // Dismiss if dragged far enough up
                        withAnimation(.easeOut(duration: 0.3)) {
                            dragOffset = -200
                            opacity = 0
                            scale = 0.8
                        }
                        
                        // Call dismiss after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    } else {
                        // Spring back to original position
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            dragOffset = 0
                            scale = 1.0
                            opacity = 1.0
                            isDragging = false
                        }
                    }
                }
        )
        .onAppear {
            // Reset drag state when notification appears
            dragOffset = 0
            scale = 1.0
            opacity = 1.0
            isDragging = false
        }
    }
}

// MARK: - Notification Container
struct NotificationContainer: View {
    @StateObject private var notificationManager = InAppNotificationManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            if let notification = notificationManager.currentNotification {
                InAppNotificationView(notification: notification) {
                    notificationManager.dismissCurrentNotification()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Optional: Show queue indicator
            if notificationManager.queueCount > 1 {
                HStack {
                    Spacer()
                    Text("\(notificationManager.queueCount - 1) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.regularMaterial)
                        )
                        .padding(.horizontal)
                }
            }
        }
        .animation(.spring(), value: notificationManager.currentNotification)
    }
}

// MARK: - Extension for Easy Usage
extension View {
    func withInAppNotifications() -> some View {
        ZStack(alignment: .top) {
            self
            NotificationContainer()
                .zIndex(1000)
        }
    }
}
