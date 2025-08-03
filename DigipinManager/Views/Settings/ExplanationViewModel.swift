//
//  ExplanationViewModel.swift
//  DigipinManager
//
//  Created by Rishi Singh on 03/08/25.
//

import SwiftUI
import MapKit

@Observable
class ExplanationViewModel {
    private(set) var allBounds: [[Square]] = [
        [], [], [], [], [], [], [], [], [], [], [], []
    ]
    
    // Average length of one degree (approximate, varies with latitude)
    let metersPerDegreeLat = 111_000.0 // approx. 111 km
    
    var position: MapCameraPosition = .region(MKCoordinateRegion(
            center: .init(latitude: 20.5, longitude: 81.5),
            span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
        ))
    
    var highlightedIndex = 0
    let digipin: String = "39J-429-L4T4"
    
    init() {
        allBounds[highlightedIndex] = self.divideSquareInto16(corners: ExplanationViewModel.outerBoundPoints)
    }
}

// MARK: - Methods
extension ExplanationViewModel {
    func metersPerDegreeLon(at latitude: Double) -> Double {
        return 111_320.0 * cos(latitude * .pi / 180)
    }

    func divideSquareInto16(topLeft: MKMapPoint, topRight: MKMapPoint, bottomRight: MKMapPoint, bottomLeft: MKMapPoint) -> [Square] {
        var squares: [Square] = []

        let numDivisions = 4

        let deltaLat = (topLeft.coordinate.latitude - bottomLeft.coordinate.latitude) / Double(numDivisions)
        let deltaLon = (topRight.coordinate.longitude - topLeft.coordinate.longitude) / Double(numDivisions)
        
        // Naming grid (top-left to bottom-right)
            let nameGrid: [[String]] = [
                ["F", "C", "9", "8"],
                ["J", "3", "2", "7"],
                ["K", "4", "5", "6"],
                ["L", "M", "P", "T"]
            ]

        for i in 0..<numDivisions {
            for j in 0..<numDivisions {
                let lat1 = topLeft.coordinate.latitude - (deltaLat * Double(i))
                let lat2 = topLeft.coordinate.latitude - (deltaLat * Double(i + 1))
                let lon1 = topLeft.coordinate.longitude + (deltaLon * Double(j))
                let lon2 = topLeft.coordinate.longitude + (deltaLon * Double(j + 1))
                
                let cornerTopLeft = MKMapPoint(CLLocationCoordinate2D(latitude: lat1, longitude: lon1))
                let cornerTopRight = MKMapPoint(CLLocationCoordinate2D(latitude: lat1, longitude: lon2))
                let cornerBottomRight = MKMapPoint(CLLocationCoordinate2D(latitude: lat2, longitude: lon2))
                let cornerBottomLeft = MKMapPoint(CLLocationCoordinate2D(latitude: lat2, longitude: lon1))

                let corners = [cornerTopLeft, cornerTopRight, cornerBottomRight, cornerBottomLeft]

                // Calculate centroid (average of all corners)
                let avgLat = (cornerTopLeft.coordinate.latitude + cornerTopRight.coordinate.latitude +
                              cornerBottomRight.coordinate.latitude + cornerBottomLeft.coordinate.latitude) / 4.0
                let avgLon = (cornerTopLeft.coordinate.longitude + cornerTopRight.coordinate.longitude +
                              cornerBottomRight.coordinate.longitude + cornerBottomLeft.coordinate.longitude) / 4.0

                let centroid = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
                let name = nameGrid[i][j]

                let square = Square(corners: corners, centroid: centroid, name: name)
                squares.append(square)
            }
        }

        return squares
    }
    
    func divideSquareInto16(corners: [MKMapPoint]) -> [Square] {
        divideSquareInto16(topLeft: corners[0], topRight: corners[1], bottomRight: corners[2], bottomLeft: corners[3])
    }
    
    func moveBack() {
        var newIndex = highlightedIndex - 1
        // Skip over dashes
        if highlightedIndex == 4 || highlightedIndex == 8 {
            newIndex -= 1
        }
        newIndex = min(max(newIndex, 0), digipin.count - 1)

        guard let prevCharacter = digipin[safe: newIndex] else { return }
        let prevBounds = allBounds[newIndex]
        let newBound = prevBounds.first {
            $0.name.lowercased() == prevCharacter.lowercased()
        }
        guard let newBound = newBound else { return }

        let newMapDelta = getMapSizeMeters(index: newIndex)
        withAnimation(.easeInOut(duration: 2.0)) {
            position = .region(MKCoordinateRegion(
                center: newBound.centroid,
                span: MKCoordinateSpan(latitudeDelta: newMapDelta, longitudeDelta: newMapDelta)
            ))
        }

        allBounds[highlightedIndex] = []

        // Update the index
        highlightedIndex = newIndex
    }
    
    func moveForewards() {
        var newIndex = highlightedIndex + 1
        // Skip over dashes
        if (highlightedIndex == 2 || highlightedIndex == 6) {
            newIndex += 1
        }
        newIndex = min(max(newIndex, 0), digipin.count - 1)
        
        guard let currentCharacter = digipin[safe: highlightedIndex] else { return }
        // String(currentCharacter)
        let currentBounds = allBounds[highlightedIndex]
        let newBound = currentBounds.first {
            $0.name.lowercased() == currentCharacter.lowercased()
        }
        guard let newBound = newBound else { return }
        let newMapDelta = getMapSizeMeters(index: newIndex)
        withAnimation(.easeInOut(duration: 2.0)) {
            position = .region(MKCoordinateRegion(
                center: newBound.centroid,
                span: MKCoordinateSpan(latitudeDelta: newMapDelta, longitudeDelta: newMapDelta)
            ))
        }
        allBounds[newIndex] = self.divideSquareInto16(corners: newBound.corners)

        // Clamp to bounds
        highlightedIndex = newIndex
    }
    
    func getMapSizeMeters(index: Int) -> CLLocationDistance {
        return ExplanationViewModel.initialMapSizeDelta / pow(2.8, Double(index))
    }
    
    func getPolygonStroke(name: String, index: Int) -> Color {
        (digipin[safe: highlightedIndex] ?? "").lowercased() == name.lowercased() && index == highlightedIndex ? Self.colors[index] : Color.white
    }
}

// MARK: - Static properties
extension ExplanationViewModel {
    static let colors: [Color] = [
        .red, .blue, .orange, .green, .orange, .cyan, .purple, .pink, .indigo, .mint, .teal, .yellow
    ]
    static let initialMapSizeDelta: Double = 40
    static let outerBoundPoints: [MKMapPoint] = [
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 38.5,
            longitude: 63.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 38.5,
            longitude: 99.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 2.5,
            longitude: 99.5
        )),
        MKMapPoint(CLLocationCoordinate2D(
            latitude: 2.5,
            longitude: 63.5
        ))
    ]
}

struct Square: Identifiable, Equatable, Hashable {
    var id: String {
        String(format: "%.6f, %.6f", self.centroid.latitude, self.centroid.longitude)
    }
    
    public static func == (lhs: Square, rhs: Square) -> Bool {
        lhs.centroid.latitude == rhs.centroid.latitude && lhs.centroid.longitude == rhs.centroid.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(centroid.latitude)
        hasher.combine(centroid.longitude)
    }
    
    var corners: [MKMapPoint]  // [topLeft, topRight, bottomRight, bottomLeft]
    var centroid: CLLocationCoordinate2D
    var name: String
}
