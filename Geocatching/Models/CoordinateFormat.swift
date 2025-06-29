import Foundation

enum CoordinateFormat: String, CaseIterable {
    case dd = "DD"
    case ddm = "DDM"
    case dms = "DMS"
    
    var displayName: String {
        switch self {
        case .dd:
            return "DD (Decimal Degrees)"
        case .ddm:
            return "DDM (Degrees Decimal Minutes)"
        case .dms:
            return "DMS (Degrees Minutes Seconds)"
        }
    }
    
    var fieldCount: Int {
        switch self {
        case .dd:
            return 1
        case .ddm:
            return 2
        case .dms:
            return 3
        }
    }
}

enum CoordinateDirection: String, CaseIterable {
    case north = "N"
    case south = "S"
    case east = "E"
    case west = "W"
    
    var isLatitude: Bool {
        return self == .north || self == .south
    }
}

struct Coordinate: Equatable {
    var direction: CoordinateDirection
    var degrees: Int
    var minutes: Int
    var seconds: Int
    var decimalDegrees: Double
    var decimalMinutes: Double
    
    init(direction: CoordinateDirection = .north, degrees: Int = 0, minutes: Int = 0, seconds: Int = 0, decimalDegrees: Double = 0.0, decimalMinutes: Double = 0.0) {
        self.direction = direction
        self.degrees = degrees
        self.minutes = minutes
        self.seconds = seconds
        self.decimalDegrees = decimalDegrees
        self.decimalMinutes = decimalMinutes
    }
    
    func toDecimalDegrees() -> Double {
        let decimal = Double(degrees) + Double(minutes)/60.0 + Double(seconds)/3600.0
        return (direction == .south || direction == .west) ? -decimal : decimal
    }
    
    static func fromDecimalDegrees(_ decimal: Double, isLatitude: Bool) -> Coordinate {
        let isNegative = decimal < 0
        let absDecimal = abs(decimal)
        
        let degrees = Int(absDecimal)
        let minutesDecimal = (absDecimal - Double(degrees)) * 60.0
        let minutes = Int(minutesDecimal)
        let seconds = Int((minutesDecimal - Double(minutes)) * 60.0)
        
        let direction: CoordinateDirection
        if isLatitude {
            direction = isNegative ? .south : .north
        } else {
            direction = isNegative ? .west : .east
        }
        
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
