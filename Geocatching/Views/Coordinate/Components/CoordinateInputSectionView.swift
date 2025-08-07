import SwiftUI

struct CoordinateInputSectionView: View {
    let title: String
    let format: CoordinateFormat
    @Binding var latitude: Coordinate
    @Binding var longitude: Coordinate
    let latitudeInputID: UUID
    let longitudeInputID: UUID
    let onFieldComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            headerView
            coordinateLabels
            coordinateInputs
        }
        .padding(.horizontal, 20)
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
                        .fill(Color.blue.opacity(0.1))
                )
        }
    }
    
    private var coordinateLabels: some View {
        HStack(spacing: 12) {
            coordinateLabel("Latitude")
            coordinateLabel("Longitude")
        }
        .padding(.bottom, 4)
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
    
    private var coordinateInputs: some View {
        HStack(spacing: 12) {
            CoordinateInputView(
                coordinate: $latitude,
                format: format,
                isLatitude: true,
                onFieldComplete: onFieldComplete
            )
            .id(latitudeInputID)
            
            CoordinateInputView(
                coordinate: $longitude,
                format: format,
                isLatitude: false,
                onFieldComplete: {
                    onFieldComplete()
                }
            )
            .id(longitudeInputID)
        }
    }
    
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.secondary.opacity(0.06))
            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
    }
}