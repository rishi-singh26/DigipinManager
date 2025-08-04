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
        ScrollView {
            HighlightCharacterView(text: viewState.digipin, highlightIndex: viewState.highlightedIndex, highlightColor: .orange.opacity(0.6))
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top, 25)
            
            Map(position: $viewState.position) {
                Marker("Hello", coordinate: CLLocationCoordinate2D(latitude: 28.612906, longitude: 77.229528))
                ForEach(viewState.allBounds.indices) { index in
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
            .frame(width: UIScreen.main.bounds.width - 40, height: UIScreen.main.bounds.width)
            .cornerRadius(10)
            .clipShape(.rect(cornerRadius: 10))
            
            HStack {
                Button(action: viewState.moveBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Prev")
                    }
                }
                .disabled(viewState.highlightedIndex == 0)
                
                Spacer()
                
                Button(action: viewState.moveForewards) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .disabled(viewState.highlightedIndex == viewState.digipin.count - 1)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground), in: .rect(cornerRadius: 10))
            .padding(20)
            
            
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
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemBackground), in: .rect(cornerRadius: 10))
            .padding(20)
            
        }
        .withURLConfirmation($showURLConfirmation, url: selectedURLForConfirmation ?? "")

    }
}

#Preview {
    SettingsView()
}
