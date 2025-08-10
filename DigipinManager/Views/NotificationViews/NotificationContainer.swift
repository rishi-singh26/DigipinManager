//
//  NotificationContainer.swift
//  DigipinManager
//
//  Created by Rishi Singh on 10/08/25.
//

import SwiftUI

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

fileprivate struct InAppNotificationSelector: View {
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
            case .coordsToPinConverter:
                CoordinateToPinNotificationView(notification: notification, index: index)
            }
        }
    }
}
