import SwiftUI

struct ActionButtonsView: View {
    let coordinateViewModel: CoordinateViewModel
    let settingsViewModel: SettingsViewModel
    
    var body: some View {
        HStack {
            mapButton
            shareButton
        }
        .padding(.horizontal, 16)
    }
    
    private var mapButton: some View {
        Button(action: openInMaps) {
            HStack(spacing: 8) {
                Image(systemName: mapIconName)
                    .font(.system(size: 18))
                Text("Maps")
                    .fontWeight(.semibold)
            }
            .font(.body)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(mapButtonGradient)
            .cornerRadius(14)
            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel("Open in Maps")
    }
    
    private var shareButton: some View {
        Button(action: shareCoordinates) {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                Text("Share")
                    .fontWeight(.semibold)
            }
            .font(.body)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(shareButtonGradient)
            .cornerRadius(14)
            .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel("Share coordinates")
    }
    
    private var mapIconName: String {
        settingsViewModel.defaultMapService == "google" ? "globe.europe.africa.fill" : "map.circle.fill"
    }
    
    private var mapButtonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var shareButtonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func openInMaps() {
        let service: MapService = settingsViewModel.defaultMapService == "google" ? .googleMaps : .appleMaps
        if let url = coordinateViewModel.getMapURL(service: service) {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareCoordinates() {
        let coordinates = coordinateViewModel.getFormattedCoordinatesString()
        shareToMessenger(coordinates: coordinates)
    }
    
    private func shareToMessenger(coordinates: String) {
        let activityViewController = UIActivityViewController(
            activityItems: [coordinates],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(
                    x: rootViewController.view.bounds.midX,
                    y: rootViewController.view.bounds.midY,
                    width: 0, 
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
            rootViewController.present(activityViewController, animated: true)
        }
    }
}