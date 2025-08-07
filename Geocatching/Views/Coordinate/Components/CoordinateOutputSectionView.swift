
import SwiftUI

struct CoordinateOutputSectionView: View {
    let title: String
    let format: CoordinateFormat
    let latitude: Coordinate
    let longitude: Coordinate
    
    var body: some View {
        VStack(spacing: 6) {
            headerView
            coordinateLabels
            coordinateDisplays
        }
        .padding(.vertical, 16)
        .background(sectionBackground)
        .padding(.horizontal, 16)
    }
    
    private var headerView: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            Text(format.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green.opacity(0.1))
                )
        }
        .padding(.horizontal, 20)
    }
    
    private var coordinateLabels: some View {
        HStack(spacing: 12) {
            coordinateLabel("Latitude")
            coordinateLabel("Longitude")
        }
        .padding(.bottom, 4)
        .padding(.horizontal, 20)
    }
    
    private func coordinateLabel(_ text: String) -> some View {
        VStack(spacing: 4) {
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var coordinateDisplays: some View {
        HStack(spacing: 12) {
            CoordinateDisplayView(
                coordinate: latitude,
                format: format,
                isLatitude: true
            )
            CoordinateDisplayView(
                coordinate: longitude,
                format: format,
                isLatitude: false
            )
        }
    }
    
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.green.opacity(0.08))
            .stroke(Color.green.opacity(0.2), lineWidth: 1)
    }
}