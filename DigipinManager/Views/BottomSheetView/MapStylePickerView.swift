//
//  MapStylePickerView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 03/08/25.
//

import SwiftUI
import MapKit

struct MapStylePickerView: View {
    @EnvironmentObject private var mapController: MapController
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text("Choose Map")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                CButton.XMarkBtn {
                    dismiss()
                }
            }
            .padding()
            HStack(spacing: 20) {
                BuildCard(name: "Standard", value: .standard)
                BuildCard(name: "Satelite", value: .imagery)
            }
            .padding()
            
            Spacer()
        }
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func BuildCard(name: String, value: MapStyleType) -> some View {
        ZStack(alignment: .bottom) {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            HStack {
                Text(name)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background {
                Rectangle()
                    .fill(.thinMaterial)
            }
        }
        .clipShape(.rect(cornerRadius: 12))
        .background {
            RoundedRectangle(cornerRadius: 12)
                .stroke(mapController.selectedMapStyleType == value ? Color.blue : Color.clear, lineWidth: 6)
        }
        .onTapGesture {
            withAnimation {
                mapController.selectedMapStyleType = value
            }
        }
    }
}

#Preview {
    @Previewable @State var showPicker: Bool = false
    
    List {
        Button("Show Map Style Picker") {
            showPicker = true
        }
    }
    .sheet(isPresented: $showPicker, content: {
        MapStylePickerView()
            .presentationDetents([.height(350)])
    })
    .environmentObject(MapController.shared)
}
