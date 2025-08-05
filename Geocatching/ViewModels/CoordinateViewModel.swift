import Foundation
import SwiftUI
import Combine

@MainActor
class CoordinateViewModel: ObservableObject {
    private var saveTimer: Timer?
    
    @Published var latitude: Coordinate {
        didSet {
            scheduleCoordinatesSave()
            convert()
        }
    }
    
    @Published var longitude: Coordinate {
        didSet {
            scheduleCoordinatesSave()
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
        
        setupNotifications()
        loadSavedData()
        convert()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func applicationWillResignActive() {
        saveTimer?.invalidate()
        saveCoordinates()
    }
    
    private func loadSavedData() {
        let savedLat = UserDefaults.standard.string(forKey: latitudeKey)
        let savedLon = UserDefaults.standard.string(forKey: longitudeKey)
        let savedFromFormat = UserDefaults.standard.string(forKey: fromFormatKey)
        let savedToFormat = UserDefaults.standard.string(forKey: toFormatKey)
        
        if let latString = savedLat,
           let lat = Coordinate.fromString(latString, direction: .north) {
            self.latitude = lat
            self.convertedLatitude = lat
        }
        
        if let lonString = savedLon,
           let lon = Coordinate.fromString(lonString, direction: .east) {
            self.longitude = lon
            self.convertedLongitude = lon
        }
        
        if let fromFormatString = savedFromFormat,
           let format = CoordinateFormat(rawValue: fromFormatString) {
            self.fromFormat = format
        }
        
        if let toFormatString = savedToFormat,
           let format = CoordinateFormat(rawValue: toFormatString) {
            self.toFormat = format
        }
    }
    
    private func scheduleCoordinatesSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.saveCoordinates()
        }
    }
    
    private func saveCoordinates() {
        let latString = latitude.toString()
        let lonString = longitude.toString()
        
        let existingLat = UserDefaults.standard.string(forKey: latitudeKey)
        let existingLon = UserDefaults.standard.string(forKey: longitudeKey)
        
        if existingLat != latString {
            UserDefaults.standard.set(latString, forKey: latitudeKey)
        }
        
        if existingLon != lonString {
            UserDefaults.standard.set(lonString, forKey: longitudeKey)
        }
        
        if existingLat != latString || existingLon != lonString {
            UserDefaults.standard.synchronize()
            
            let savedLat = UserDefaults.standard.string(forKey: latitudeKey)
            let savedLon = UserDefaults.standard.string(forKey: longitudeKey)
        }
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