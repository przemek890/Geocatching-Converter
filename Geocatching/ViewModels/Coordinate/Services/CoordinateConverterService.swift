import Foundation

protocol CoordinateConverterServiceProtocol {
    func convert(latitude: Coordinate, longitude: Coordinate, from fromFormat: CoordinateFormat, to toFormat: CoordinateFormat) -> (latitude: Coordinate, longitude: Coordinate)
    func getMapURL(latitude: Coordinate, longitude: Coordinate, format: CoordinateFormat, service: MapService) -> URL?
    func getFormattedCoordinatesString(latitude: Coordinate, longitude: Coordinate, format: CoordinateFormat) -> String
}

class CoordinateConverterService: CoordinateConverterServiceProtocol {
    
    func convert(latitude: Coordinate, longitude: Coordinate, from fromFormat: CoordinateFormat, to toFormat: CoordinateFormat) -> (latitude: Coordinate, longitude: Coordinate) {
        let latDecimal = getDecimalDegreesForCoordinate(latitude, format: fromFormat)
        let lonDecimal = getDecimalDegreesForCoordinate(longitude, format: fromFormat)
        
        let convertedLatitude = convertFromDecimal(latDecimal, isLatitude: true, to: toFormat)
        let convertedLongitude = convertFromDecimal(lonDecimal, isLatitude: false, to: toFormat)
        
        return (latitude: convertedLatitude, longitude: convertedLongitude)
    }
    
    func getMapURL(latitude: Coordinate, longitude: Coordinate, format: CoordinateFormat, service: MapService) -> URL? {
        let latDecimal = getDecimalDegreesForCoordinate(latitude, format: format)
        let lonDecimal = getDecimalDegreesForCoordinate(longitude, format: format)
        
        switch service {
        case .appleMaps:
            let urlString = "http://maps.apple.com/?q=\(latDecimal),\(lonDecimal)"
            return URL(string: urlString)
        case .googleMaps:
            let urlString = "https://www.google.com/maps/search/?api=1&query=\(latDecimal),\(lonDecimal)"
            return URL(string: urlString)
        }
    }
    
    func getFormattedCoordinatesString(latitude: Coordinate, longitude: Coordinate, format: CoordinateFormat) -> String {
        switch format {
        case .dd:
            return String(format: "%@ %.5f°, %@ %.5f°",
                         latitude.direction.rawValue, latitude.decimalDegrees,
                         longitude.direction.rawValue, longitude.decimalDegrees)
        case .ddm:
            return String(format: "%@ %02d° %.3f', %@ %03d° %.3f'",
                         latitude.direction.rawValue, latitude.degrees, latitude.decimalMinutes,
                         longitude.direction.rawValue, longitude.degrees, longitude.decimalMinutes)
        case .dms:
            return String(format: "%@ %02d° %02d' %02d\", %@ %03d° %02d' %02d\"",
                         latitude.direction.rawValue, latitude.degrees, latitude.minutes, latitude.seconds,
                         longitude.direction.rawValue, longitude.degrees, longitude.minutes, longitude.seconds)
        }
    }
    
    private func getDecimalDegreesForCoordinate(_ coordinate: Coordinate, format: CoordinateFormat) -> Double {
        switch format {
        case .dd:
            let decimal = coordinate.decimalDegrees
            return (coordinate.direction == .south || coordinate.direction == .west) ? -decimal : decimal
        case .ddm:
            let decimal = Double(coordinate.degrees) + coordinate.decimalMinutes/60.0
            return (coordinate.direction == .south || coordinate.direction == .west) ? -decimal : decimal
        case .dms:
            return coordinate.toDecimalDegrees()
        }
    }
    
    private func convertFromDecimal(_ decimal: Double, isLatitude: Bool, to format: CoordinateFormat) -> Coordinate {
        let isNegative = decimal < 0
        let absDecimal = abs(decimal)
        
        let direction: CoordinateDirection
        if isLatitude {
            direction = isNegative ? .south : .north
        } else {
            direction = isNegative ? .west : .east
        }
        
        let degrees = Int(absDecimal)
        let minutesDecimal = (absDecimal - Double(degrees)) * 60.0
        let minutes = Int(minutesDecimal)
        let secondsDecimal = (minutesDecimal - Double(minutes)) * 60.0
        let seconds = Int(secondsDecimal)
        
        return Coordinate(
            direction: direction,
            degrees: degrees,
            minutes: minutes,
            seconds: seconds,
            decimalDegrees: absDecimal,
            decimalMinutes: minutesDecimal
        )
    }
}