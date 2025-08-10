//
//  AudioControlNotificationView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 09/08/25.
//

import SwiftUI

struct AudioControlNotificationView: View {
    @EnvironmentObject private var notificationManager:  InAppNotificationManager

    let notification: InAppNotification
    let index: Int
    let autoPlay: Bool
    
    @State private var isPlaying: Bool = true
    
    init(notification: InAppNotification, index: Int, autoPlay: Bool = true) {
        self.notification = notification
        self.index = index
        self.autoPlay = autoPlay
        
        _isPlaying = State(wrappedValue: autoPlay)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Text(notification.title ?? "")
                        .font(.title)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    CButton.XMarkFillBtn(action: removeNotification)
                }
                
                HStack {
                    Button {
                        if isPlaying {
                            SpeechManager.shared.stop()
                        } else {
                            playAudio()
                        }
                        updatePlayStatus(with: !isPlaying)
                    } label: {
                        Label(isPlaying ? "Stop" : "Play", systemImage: isPlaying ? "stop.circle" : "play.circle")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(isPlaying ? .red : .orange, in: .capsule)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: removeNotification) {
                        Text("Done")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor, in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 50, x: -3, y: -3)
                .shadow(color: .black.opacity(0.2), radius: 50, x: 3, y: 3)
        }
        .contentShape(.rect(cornerRadius: 40))
        .padding(.horizontal, 10)
        .gesture(gesture)
        .onAppear {
            guard autoPlay else { return }
            playAudio()
        }
    }
    
    private func playAudio() {
        Task {
            guard let text = notification.title else { return }
            try? await Task.sleep(for: .seconds(0.3))
            await SpeechManager.shared.speakPin(text)
            self.updatePlayStatus(with: false)
        }
    }
    
    private func updatePlayStatus(with status: Bool) {
        withAnimation {
            self.isPlaying = status
        }
    }
    
    private func removeNotification() {
        SpeechManager.shared.stop()
        notificationManager.removeNotification(notification.id)
    }
    
    private var gesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let xOffset = value.translation.width < 0 ? value.translation.width : 0
                notificationManager.notificationQueue[index].offsetX = xOffset
            }.onEnded { value in
                let xOffset = value.translation.width + (value.velocity.width / 2)
                
                if -xOffset > 200 {
                    // Remove notification
                    removeNotification()
                } else {
                    // Reset notification position
                    if notificationManager.notificationQueue.indices.contains(index) {
                        withAnimation(.snappy) {
                            notificationManager.notificationQueue[index].offsetX = 0
                        }
                    }
                }
            }
    }
}

#Preview {
    AudioControlNotificationView(
        notification: .init(title: "2kl-j34-2233", message: "This is a notification", type: .neutral, mode: .audioContoll),
        index: 0,
        autoPlay: false
    )
    .environmentObject(InAppNotificationManager.shared)
}
