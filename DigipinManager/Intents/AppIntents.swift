//
//  AppIntents.swift
//  DigipinManager
//
//  Created by Rishi Singh on 04/08/25.
//

import SwiftUI
import AppIntents

// MARK: - Shared Service and Utilities
protocol DigipinServiceProtocol {
    static var digipinService: DIGIPIN { get }
}

extension DigipinServiceProtocol {
    static var digipinService: DIGIPIN { DIGIPIN() }
    
    func getCoordinates(from pin: String) -> Coordinate? {
        return try? Self.digipinService.coordinate(from: pin.uppercased())
    }
    
    func validateAndGetCoordinates(from pin: String) throws -> Coordinate {
        guard let coordinates = getCoordinates(from: pin) else {
            throw ValidationError.invalidDigipin
        }
        return coordinates
    }
    
    func validateCoordinates(latitude: Double, longitude: Double) throws {
        guard latitude >= 2.5 && latitude <= 38.5 else {
            throw ValidationError.invalidLatitude
        }
        
        guard longitude >= 63.5 && longitude <= 99.5 else {
            throw ValidationError.invalidLongitude
        }
    }
    
    func generateDIGIPIN(latitude: Double, longitude: Double) throws -> String {
        try validateCoordinates(latitude: latitude, longitude: longitude)
        
        guard let digipin = try? Self.digipinService.generateDIGIPIN(latitude: latitude, longitude: longitude) else {
            throw ValidationError.coordinatesOutOfBounds
        }
        
        return digipin
    }
}

// MARK: - URL Generation Utilities
enum MapURLGenerator {
    static func createGoogleMapsURL(latitude: Double, longitude: Double) -> String {
        return "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)"
    }
    
    static func createAppleMapsURL(latitude: Double, longitude: Double) -> String {
        return "http://maps.apple.com/?ll=\(latitude),\(longitude)&q=Location"
    }
}

// MARK: - Map URLs from DIGIPIN
struct URLsFromDigipinIntent: AppIntent, DigipinServiceProtocol {
    static var title: LocalizedStringResource = "Map URLs for DIGIPIN"
    static var description = IntentDescription("Create Map URLs for given DIGIPIN. Return the URLs in a list.")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "DIGIPIN", description: "DIGIPIN (XXX-XXX-XXXX)")
    var digipin: String
    
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let coordinates = try validateAndGetCoordinates(from: digipin)
        
        let urls = [
            MapURLGenerator.createGoogleMapsURL(latitude: coordinates.latitude, longitude: coordinates.longitude),
            MapURLGenerator.createAppleMapsURL(latitude: coordinates.latitude, longitude: coordinates.longitude)
        ]
        
        return .result(value: urls)
    }
}

// MARK: - Google Map URL from DIGIPIN
//struct GoogleMapURLFromDigipinIntent: AppIntent, DigipinServiceProtocol {
//    static var title: LocalizedStringResource = "Google Map URL for DIGIPIN"
//    static var description = IntentDescription("Create Google Maps URL for given DIGIPIN.")
//    static var openAppWhenRun: Bool = false
//    
//    @Parameter(title: "DIGIPIN", description: "DIGIPIN (XXX-XXX-XXXX)")
//    var digipin: String
//    
//    func perform() async throws -> some IntentResult & ReturnsValue<String> {
//        let coordinates = try validateAndGetCoordinates(from: digipin)
//        let googleMapsURL = MapURLGenerator.createGoogleMapsURL(latitude: coordinates.latitude, longitude: coordinates.longitude)
//        
//        return .result(value: googleMapsURL)
//    }
//}

// MARK: - Apple Map URL from DIGIPIN
//struct AppleMapURLFromDigipinIntent: AppIntent, DigipinServiceProtocol {
//    static var title: LocalizedStringResource = "Apple Map URL for DIGIPIN"
//    static var description = IntentDescription("Create Apple Maps URL for given DIGIPIN.")
//    static var openAppWhenRun: Bool = false
//    
//    @Parameter(title: "DIGIPIN", description: "DIGIPIN (XXX-XXX-XXXX)")
//    var digipin: String
//    
//    func perform() async throws -> some IntentResult & ReturnsValue<String> {
//        let coordinates = try validateAndGetCoordinates(from: digipin)
//        let appleMapsURL = MapURLGenerator.createAppleMapsURL(latitude: coordinates.latitude, longitude: coordinates.longitude)
//        
//        return .result(value: appleMapsURL)
//    }
//}

// MARK: - Coordinates from DIGIPIN
struct CoordinatesFromDigipinIntent: AppIntent, DigipinServiceProtocol {
    static var title: LocalizedStringResource = "Get Coordinates for DIGIPIN"
    static var description = IntentDescription("Get latitude and longitude for given DIGIPIN.")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "DIGIPIN", description: "DIGIPIN (XXX-XXX-XXXX)")
    var digipin: String
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let coordinates = try validateAndGetCoordinates(from: digipin)
        
        return .result(
            value: String(format: "Latitude: %.7f\nLongitude: %.7f", coordinates.latitude, coordinates.longitude)
        )
    }
}

// MARK: - Validate DIGIPIN
struct ValidateDigipinIntent: AppIntent, DigipinServiceProtocol {
    static var title: LocalizedStringResource = "Validate DIGIPIN"
    static var description = IntentDescription("Verify if the provided digipin is valid.")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "DIGIPIN", description: "DIGIPIN (XXX-XXX-XXXX)")
    var digipin: String
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let isValid = getCoordinates(from: digipin) != nil
        return .result(value: isValid)
    }
}

// MARK: - Validate Coordinates
struct ValidateCoordinatesIntent: AppIntent, DigipinServiceProtocol {
    static var title: LocalizedStringResource = "Validate Coordinates"
    static var description = IntentDescription("Verify if the provided coordinates is within the bounds supported by DIGIPIN.")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Latitude", description: "Latitude coordinate (2.5 to 38.5)")
    var latitude: Double
    
    @Parameter(title: "Longitude", description: "Longitude coordinate (63.5 to 99.5)")
    var longitude: Double
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        do {
            _ = try generateDIGIPIN(latitude: latitude, longitude: longitude)
            return .result(value: true)
        } catch {
            return .result(value: false)
        }
    }
}

// MARK: - Get DIGIPIN from coordinates
struct DigipinFromCoordinatesIntent: AppIntent, DigipinServiceProtocol {
    static var title: LocalizedStringResource = "Get DIGIPIN for Coordinates"
    static var description = IntentDescription("Get DIGIPIN from provided coordinates.")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Latitude", description: "Latitude coordinate (2.5 to 38.5)")
    var latitude: Double
    
    @Parameter(title: "Longitude", description: "Longitude coordinate (63.5 to 99.5)")
    var longitude: Double
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let digipin = try generateDIGIPIN(latitude: latitude, longitude: longitude)
        return .result(value: digipin)
    }
}

// MARK: - Validation Errors
enum ValidationError: Error, LocalizedError, CustomNSError {
    case invalidLatitude
    case invalidLongitude
    case invalidDigipin
    case coordinatesOutOfBounds
    
    var errorDescription: String? {
        switch self {
        case .invalidLatitude:
            return "Invalid latitude: must be between 2.5 and 38.5 degrees"
        case .invalidLongitude:
            return "Invalid longitude: must be between 63.5 and 99.5 degrees"
        case .invalidDigipin:
            return "Invalid DIGIPIN: Please enter a valid DIGIPIN."
        case .coordinatesOutOfBounds:
            return "Provided coordinates are out of bounds supported by DIGIPIN"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidLatitude:
            return "The latitude value is outside the range supported by DIGIPIN"
        case .invalidLongitude:
            return "The longitude value is outside the range supported by DIGIPIN"
        case .invalidDigipin:
            return "Invalid DIGIPIN: Please enter a valid DIGIPIN."
        case .coordinatesOutOfBounds:
            return "Provided coordinates are out of bounds supported by DIGIPIN"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidLatitude:
            return "Please enter a latitude value between 2.5 and 38.5"
        case .invalidLongitude:
            return "Please enter a longitude value between 63.5 and 99.5"
        case .invalidDigipin:
            return "Please enter a valid DIGIPIN."
        case .coordinatesOutOfBounds:
            return "Please provide valid coordinates."
        }
    }
    
    static var errorDomain: String {
        return "MapCoordinatesErrorDomain"
    }
    
    var errorCode: Int {
        switch self {
        case .invalidLatitude:
            return 1001
        case .invalidLongitude:
            return 1002
        case .invalidDigipin:
            return 1003
        case .coordinatesOutOfBounds:
            return 1004
        }
    }
    
    var errorUserInfo: [String : Any] {
        return [
            NSLocalizedDescriptionKey: errorDescription ?? "Unknown error",
            NSLocalizedFailureReasonErrorKey: failureReason ?? "",
            NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion ?? ""
        ]
    }
}
