//
//  InAppToastView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 09/08/25.
//

import SwiftUI

struct InAppToastView: View {
    @EnvironmentObject private var notificationManager:  InAppNotificationManager
    @State private var delayTask: DispatchWorkItem?

    let notification: InAppNotification
    let index: Int
    var autoDismiss: Bool = true
    
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
                
                Button {
                    if let delayTask {
                        delayTask.cancel()
                    }
                    notificationManager.removeNotification(notification.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
                .accessibilityLabel("Dismiss notification")
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background {
            Capsule()
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
        }
        .contentShape(.capsule)
        .padding(.horizontal, 10)
        .gesture(gesture)
        .onAppear(perform: createDelayTask)
    }
    
    private func createDelayTask() {
        guard autoDismiss else { return } // create delay task if autoDismiss is true
        guard delayTask == nil else { return }
        delayTask = .init(block: {
            notificationManager.simpleRemoveNotification(notification.id)
        })
        
        if let delayTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + notification.timing.rawValue, execute: delayTask)
        }
    }
    
    private func cancelDelayTask() {
        if let delayTask {
            delayTask.cancel()
            self.delayTask = nil
        }
    }
    
    private var gesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let xOffset = value.translation.width < 0 ? value.translation.width : 0
                notificationManager.notificationQueue[index].offsetX = xOffset
                cancelDelayTask()
            }.onEnded { value in
                let xOffset = value.translation.width + (value.velocity.width / 2)
                
                if -xOffset > 200 {
                    // Remove notification
                    notificationManager.removeNotification(notification.id)
                } else {
                    // Reset notification position
                    if notificationManager.notificationQueue.indices.contains(index) {
                        withAnimation(.snappy) {
                            notificationManager.notificationQueue[index].offsetX = 0
                        }
                        createDelayTask()
                    }
                }
            }
    }
}

#Preview {
    InAppToastView(
        notification: .init(title: "Alert", message: "This is a notification", type: .info, mode: .toast),
        index: 0,
        autoDismiss: false
    )
    .environmentObject(InAppNotificationManager.shared)
}
