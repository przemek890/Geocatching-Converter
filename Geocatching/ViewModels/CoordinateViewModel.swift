import Foundation
import SwiftUI
import Combine

@MainActor
class CoordinateViewModel: ObservableObject {
    @Published var latitude: Coordinate {
        didSet {
            saveCoordinates()
            convert()
        }
    }
    
    @Published var longitude: Coordinate {
        didSet {
            saveCoordinates()
            convert()
        }
    }
    
    @Published var convertedLatitude = Coordinate(direction: .north)
    @Published var convertedLongitude = Coordinate(direction: .east)
    
    @Published var fromFormat: CoordinateFormat {
        didSet {
            saveFormat()
            convert()
        }
    }
    
    @Published var toFormat: CoordinateFormat {
        didSet {
            saveFormat()
            convert()
        }
    }
    
    private let converter = CoordinateConverter()
    private var cancellables = Set<AnyCancellable>()
    
    private let latitudeKey = "savedLatitude"
    private let longitudeKey = "savedLongitude"
    private let fromFormatKey = "savedFromFormat"
    private let toFormatKey = "savedToFormat"
    
    init() {
        self.latitude = Coordinate(direction: .north)
        self.longitude = Coordinate(direction: .east)
        self.fromFormat = .ddm
        self.toFormat = .dd
        
        loadSavedData()
        
        convert()
    }
    
    private func loadSavedData() {
        if let latString = UserDefaults.standard.string(forKey: latitudeKey),
           let lat = Coordinate.fromString(latString, direction: .north) {
            self.latitude = lat
        }
        
        if let lonString = UserDefaults.standard.string(forKey: longitudeKey),
           let lon = Coordinate.fromString(lonString, direction: .east) {
            self.longitude = lon
        }
        
        if let fromFormatString = UserDefaults.standard.string(forKey: fromFormatKey),
           let format = CoordinateFormat(rawValue: fromFormatString) {
            self.fromFormat = format
        }
        
        if let toFormatString = UserDefaults.standard.string(forKey: toFormatKey),
           let format = CoordinateFormat(rawValue: toFormatString) {
            self.toFormat = format
        }
    }
    
    private func saveCoordinates() {
        UserDefaults.standard.set(latitude.toString(), forKey: latitudeKey)
        UserDefaults.standard.set(longitude.toString(), forKey: longitudeKey)
    }
    
    private func saveFormat() {
        UserDefaults.standard.set(fromFormat.rawValue, forKey: fromFormatKey)
        UserDefaults.standard.set(toFormat.rawValue, forKey: toFormatKey)
    }
    
    func convert() {
        let result = converter.convert(
            latitude: latitude,
            longitude: longitude,
            from: fromFormat,
            to: toFormat
        )
        
        convertedLatitude = result.latitude
        convertedLongitude = result.longitude
    }
    
    func resetInput() {
        withAnimation(.easeInOut(duration: 0.3)) {
            latitude = Coordinate(direction: .north)
            longitude = Coordinate(direction: .east)
            convert()
        }
        saveCoordinates()
    }
    
    func getFormattedCoordinatesString() -> String {
        return converter.getFormattedCoordinatesString(
            latitude: convertedLatitude,
            longitude: convertedLongitude,
            format: toFormat
        )
    }
    
    func getMapURL(service: MapService) -> URL? {
        return converter.getMapURL(
            latitude: convertedLatitude,
            longitude: convertedLongitude,
            format: toFormat,
            service: service
        )
    }
    
    func getFormatLabel(for format: CoordinateFormat, isLatitude: Bool) -> String {
        switch format {
        case .dd:
            return "Decimal degrees"
        case .ddm:
            return "Degrees° Minutes.mm'"
        case .dms:
            return "Degrees° Minutes' Seconds\""
        }
    }
}

enum MapService {
    case appleMaps
    case googleMaps
}