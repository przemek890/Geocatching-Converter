import SwiftUI

struct CoordinateDisplayView: View {
    let coordinate: Coordinate
    let format: CoordinateFormat
    let isLatitude: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(coordinate.direction.rawValue)
                .frame(width: 25, height: 32)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(6)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.accentColor)

            switch format {
            case .dd:
                ddDisplay()
            case .ddm:
                ddmDisplay()
            case .dms:
                dmsDisplay()
            }
        }
    }

    @ViewBuilder
    private func ddDisplay() -> some View {
        HStack(spacing: 3) {
            Text(String(format: isLatitude ? "%02d" : "%03d", coordinate.degrees))
                .frame(width: isLatitude ? 35 : 40, height: 32)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Text(".")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Text(String(format: "%05d", Int((coordinate.decimalDegrees - Double(coordinate.degrees)) * 100000)))
                .frame(width: 60, height: 32)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Text("°")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func ddmDisplay() -> some View {
        HStack(spacing: 3) {
            Text(String(format: isLatitude ? "%02d" : "%03d", coordinate.degrees))
                .frame(width: isLatitude ? 35 : 40, height: 32)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Text("°")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(String(format: "%.3f", coordinate.decimalMinutes))
                .frame(width: 65, height: 32)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Text("'")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func dmsDisplay() -> some View {
        HStack(spacing: 3) {
            Text(String(format: isLatitude ? "%02d" : "%03d", coordinate.degrees))
                .frame(width: isLatitude ? 35 : 40, height: 32)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Text("°")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(String(format: "%02d", coordinate.minutes))
                .frame(width: 35, height: 32)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Text("'")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Text(String(format: "%02d", coordinate.seconds))
                .frame(width: 35, height: 32)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Text("\"")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}