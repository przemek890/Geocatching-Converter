extension Coordinate {
    func toString() -> String {
        "\(direction.rawValue),\(degrees),\(minutes),\(seconds),\(decimalDegrees),\(decimalMinutes)"
    }
    
    static func fromString(_ string: String, direction: CoordinateDirection) -> Coordinate? {
        let parts = string.split(separator: ",").map { String($0) }
        guard parts.count == 6,
              let deg = Int(parts[1]),
              let min = Int(parts[2]),
              let sec = Int(parts[3]),
              let decDeg = Double(parts[4]),
              let decMin = Double(parts[5]),
              let dir = CoordinateDirection(rawValue: parts[0]) else { return nil }
        var coord = Coordinate(direction: dir)
        coord.degrees = deg
        coord.minutes = min
        coord.seconds = sec
        coord.decimalDegrees = decDeg
        coord.decimalMinutes = decMin
        return coord
    }
}