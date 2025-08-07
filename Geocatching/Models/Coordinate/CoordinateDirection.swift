import Foundation

enum CoordinateDirection: String, CaseIterable {
    case north = "N"
    case south = "S"
    case east = "E"
    case west = "W"
    
    var isLatitude: Bool {
        return self == .north || self == .south
    }
}