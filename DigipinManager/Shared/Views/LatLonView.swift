//
//  LatLonView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 31/07/25.
//

import SwiftUI
import MapKit

struct LatLonView: View {
    let coordinate: Coordinate?
    let prifix: String
    
    init(latitude: Double, longitude: Double, prefix: String = "") {
        self.coordinate = Coordinate(latitude: latitude, longitude: longitude)
        self.prifix = prefix
    }
    
    init(coordinates: Coordinate?, prefix: String = "") {
        self.coordinate = coordinates.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        self.prifix = prefix
    }
    
    init(_ location: CLLocation?, prefix: String = "") {
        self.coordinate = location.map { Coordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
        self.prifix = prefix
    }

    init(_ locationCoordinate: CLLocationCoordinate2D?, prefix: String = "") {
        self.coordinate = locationCoordinate.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
        self.prifix = prefix
    }
    
    var body: some View {
        Text("\(prifix)\(coordinate?.toString() ?? "")")
            .textSelection(.enabled)
    }
}

#Preview {
    LatLonView(latitude: 23.5, longitude: 63.5, prefix: "Coordinates: ")
}
