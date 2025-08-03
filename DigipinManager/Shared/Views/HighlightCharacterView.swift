//
//  HighlightCharacterView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 03/08/25.
//

import SwiftUI

struct HighlightCharacterView: View {
    let text: String
    let highlightIndex: Int
    var highlightColor: Color = .red

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .background(index == highlightIndex ? highlightColor : .clear)
            }
        }
    }
}


fileprivate struct HighlightDigipinCharView: View {
    @State private var selectedIndex = 0
    @State private var text = "XXX-XXX-XXXX"

    var body: some View {
        List {
            HighlightCharacterView(text: text, highlightIndex: selectedIndex, highlightColor: .orange)
                .font(.title.bold())

            HStack {
                Button("Previous") {
                    moveSelection(backward: true)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Next") {
                    moveSelection(backward: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func moveSelection(backward: Bool) {
        let step = backward ? -1 : 1
        var newIndex = selectedIndex + step

        // Skip over dashes
        if backward && (selectedIndex == 4 || selectedIndex == 8) {
            newIndex -= 1
        } else if !backward && (selectedIndex == 2 || selectedIndex == 6) {
            newIndex += 1
        }

        // Clamp to bounds
        selectedIndex = min(max(newIndex, 0), text.count - 1)
    }
}


#Preview {
    HighlightCharacterView(text: "Hello There".uppercased(), highlightIndex: 1)
        .font(.title.bold())
}
