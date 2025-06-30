import Foundation
import SwiftUI
import Combine

@MainActor
class CoordinateViewModel: ObservableObject {
    @Published var latitude = Coordinate(direction: .north)
    @Published var longitude = Coordinate(direction: .east)
    @Published var convertedLatitude = Coordinate(direction: .north)
    @Published var convertedLongitude = Coordinate(direction: .east)
    @Published var fromFormat: CoordinateFormat = .ddm
    @Published var toFormat: CoordinateFormat = .dd
    
    private let converter = CoordinateConverter()
    
    @AppStorage("inputLatitude") private var storedLatitude: String = ""
    @AppStorage("inputLongitude") private var storedLongitude: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if let lat = Coordinate.fromString(storedLatitude, direction: .north) {
            latitude = lat
        }
        if let lon = Coordinate.fromString(storedLongitude, direction: .east) {
            longitude = lon
        }
        convert()
        
        $latitude
            .sink { [weak self] coord in
                self?.storedLatitude = coord.toString()
            }
            .store(in: &cancellables)
        $longitude
            .sink { [weak self] coord in
                self?.storedLongitude = coord.toString()
            }
            .store(in: &cancellables)
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
