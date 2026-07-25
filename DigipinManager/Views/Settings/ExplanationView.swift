//
//  ExplanationView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 03/08/25.
//

import SwiftUI
import MapKit

struct ExplanationView: View {
    @Environment(\.openURL) private var openURL
    
    @State private var viewState = ExplanationViewModel()
    @State private var showURLConfirmation: Bool = false
    @State private var selectedURLForConfirmation: String?
    
    var body: some View {
        List {
            Map(position: $viewState.position) {
                Marker("DIGIPIN", coordinate: CLLocationCoordinate2D(latitude: 28.612906, longitude: 77.229528))
                ForEach(viewState.allBounds.indices, id: \.self) { index in
                    ForEach(viewState.allBounds[index]) { square in
                        MapPolygon(points: square.corners)
                            .foregroundStyle(Color.clear)
                            .stroke(.white, style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round))
                        
                        Annotation("", coordinate: square.centroid) {
                            Text(square.name)
                                .foregroundStyle(.white)
                                .padding()
                                .onTapGesture {
                                    print(square.name)
                                }
                        }
                    }
                }
            }
            .mapStyle(.imagery)
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(10)
            .clipShape(.rect(cornerRadius: 10))
            
            HStack {
                Button(action: viewState.moveBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Prev")
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewState.highlightedIndex == 0)
                
                Spacer()
                
                Button(action: viewState.moveForewards) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewState.highlightedIndex == viewState.digipin.count - 1)
            }
            
            
            Button(action: {
                selectedURLForConfirmation = "https://www.indiapost.gov.in/digipin"
                showURLConfirmation = true
            }, label: {
                HStack {
                    Text("Learn More")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
            })
            
        }
        .navigationTitle("Digipin Manager")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .title) {
                HighlightCharacterView(text: viewState.digipin, highlightIndex: viewState.highlightedIndex, highlightColor: .orange.opacity(0.6))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.top, 25)
            }
        }
        .withURLConfirmation($showURLConfirmation, url: selectedURLForConfirmation ?? "")

    }
}

#Preview {
    SettingsView()
}
