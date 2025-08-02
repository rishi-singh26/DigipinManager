//
//  WeatherUtility.swift
//  Pinly
//
//  Created by Rishi Singh on 01/08/25.
//

import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherUtility {
    private static let weatherService = WeatherService()

    /// Fetches weather data for the given coordinates.
    /// - Parameters:
    ///   - coordinate: The latitude and longiture of the location.
    /// - Returns: `CurrentWeather?`
    static func fetchWeather(for coordinate: GeoPoint) async ->  CurrentWeather? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let weather = try? await weatherService.weather(for: location)
        return weather?.currentWeather ?? nil
    }
}
