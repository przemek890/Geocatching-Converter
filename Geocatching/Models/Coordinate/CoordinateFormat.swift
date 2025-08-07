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