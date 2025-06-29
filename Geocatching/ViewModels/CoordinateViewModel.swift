//
//  CoordinateViewModel.swift
//  Geocatching
//
//  Created by przemek899 on 29/06/2025.
//

import Foundation
import SwiftUI

@MainActor
class CoordinateViewModel: ObservableObject {
    @Published var latitude = Coordinate(direction: .north)
    @Published var longitude = Coordinate(direction: .east)
    @Published var convertedLatitude = Coordinate(direction: .north)
    @Published var convertedLongitude = Coordinate(direction: .east)
    @Published var fromFormat: CoordinateFormat = .ddm
    @Published var toFormat: CoordinateFormat = .dd
    
    private let converter = CoordinateConverter()
    
    init() {
        convert()
    }
    
    // MARK: - Public Methods
    
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
