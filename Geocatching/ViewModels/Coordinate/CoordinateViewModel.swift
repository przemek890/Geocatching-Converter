import Foundation
import SwiftUI
import Combine

@MainActor
class CoordinateViewModel: ObservableObject {
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
    
    private var saveTimer: Timer?
    private let converterService: CoordinateConverterServiceProtocol
    private let userDefaultsService: UserDefaultsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private struct Keys {
        static let latitude = "savedLatitude"
        static let longitude = "savedLongitude"
        static let fromFormat = "savedFromFormat"
        static let toFormat = "savedToFormat"
    }
    
    init(
        converterService: CoordinateConverterServiceProtocol = CoordinateConverterService(),
        userDefaultsService: UserDefaultsServiceProtocol = UserDefaultsService()
    ) {
        self.converterService = converterService
        self.userDefaultsService = userDefaultsService
        
        self.latitude = Coordinate(direction: .north)
        self.longitude = Coordinate(direction: .east)
        self.fromFormat = .ddm
        self.toFormat = .dd
        
        setupNotifications()
        loadSavedData()
        convert()
    }
    
    func convert() {
        let result = converterService.convert(
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
        return converterService.getFormattedCoordinatesString(
            latitude: convertedLatitude,
            longitude: convertedLongitude,
            format: toFormat
        )
    }
    
    func getMapURL(service: MapService) -> URL? {
        return converterService.getMapURL(
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
        if let latString = userDefaultsService.loadString(forKey: Keys.latitude),
           let lat = Coordinate.fromString(latString, direction: .north) {
            self.latitude = lat
            self.convertedLatitude = lat
        }
        
        if let lonString = userDefaultsService.loadString(forKey: Keys.longitude),
           let lon = Coordinate.fromString(lonString, direction: .east) {
            self.longitude = lon
            self.convertedLongitude = lon
        }
        
        if let fromFormatString = userDefaultsService.loadString(forKey: Keys.fromFormat),
           let format = CoordinateFormat(rawValue: fromFormatString) {
            self.fromFormat = format
        }
        
        if let toFormatString = userDefaultsService.loadString(forKey: Keys.toFormat),
           let format = CoordinateFormat(rawValue: toFormatString) {
            self.toFormat = format
        }
    }
    
    private func scheduleCoordinatesSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.saveCoordinates()
            }
        }
    }
    
    private func saveCoordinates() {
        let latString = latitude.toString()
        let lonString = longitude.toString()
        
        let existingLat = userDefaultsService.loadString(forKey: Keys.latitude)
        let existingLon = userDefaultsService.loadString(forKey: Keys.longitude)
        
        if existingLat != latString {
            userDefaultsService.save(latString, forKey: Keys.latitude)
        }
        
        if existingLon != lonString {
            userDefaultsService.save(lonString, forKey: Keys.longitude)
        }
        
        if existingLat != latString || existingLon != lonString {
            userDefaultsService.synchronize()
        }
    }
    
    private func saveFormat() {
        userDefaultsService.save(fromFormat.rawValue, forKey: Keys.fromFormat)
        userDefaultsService.save(toFormat.rawValue, forKey: Keys.toFormat)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        saveTimer?.invalidate()
    }
}