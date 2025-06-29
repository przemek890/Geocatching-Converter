import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CoordinateViewModel()
    @FocusState private var focusedOnLatitude: Bool
    @FocusState private var focusedOnLongitude: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {        
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    Spacer().frame(height: 25)
                    
                    formatSelectionSection
                    
                    Spacer().frame(height: 12) // Zmniejszona przerwa między komponentami
                    
                    inputSection
                    
                    Spacer().frame(height: 12) // Zmniejszona przerwa między komponentami
                    
                    outputSection
                    
                    Spacer().frame(height: 16) // Zmniejszona przerwa przed przyciskami
                    
                    actionButtonsSection
                    
                    Spacer().frame(height: 100) // Dodatkowa przestrzeń na dole
                }
            }
            .scrollDisabled(true) // Blokuje przewijanie gdy nie ma klawiatury
            .navigationBarHidden(true)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .overlay(
                // Dark mode toggle button w górnym lewym rogu
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isDarkMode.toggle()
                            }
                        }) {
                            Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .padding(8)
                        }
                        .accessibilityLabel("Toggle dark mode")
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.leading, 20)
            )
            .onTapGesture {
                hideKeyboard()
            }
        }
        .onAppear {
            viewModel.convert()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedOnLatitude = true
            }
        }
        .onChange(of: viewModel.fromFormat) { _ in
            viewModel.resetInput()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedOnLatitude = true
            }
        }
        .onChange(of: viewModel.toFormat) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.convert()
            }
        }
        .onChange(of: viewModel.latitude) { _ in
            viewModel.convert()
        }
        .onChange(of: viewModel.longitude) { _ in
            viewModel.convert()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 1) {
            Image("app")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 110, height: 110)
                .cornerRadius(22)
                .shadow(color: .primary.opacity(0.2), radius: 4, x: 0, y: 3)
            
            Text("Geocatching")
                .font(.title2)
                .fontWeight(.bold)
            Text("Coordinate Converter")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity) // Wyśrodkowanie względem szerokości
        .padding(.top, 8) // Wyrównanie z przyciskiem dark mode
        .padding(.bottom, -10)
    }
    
    private var formatSelectionSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Input Format")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Menu {
                    ForEach(CoordinateFormat.allCases, id: \.self) { format in
                        Button(format.rawValue) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.fromFormat = format
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.fromFormat.rawValue)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Output Format")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Menu {
                    ForEach(CoordinateFormat.allCases, id: \.self) { format in
                        Button(format.rawValue) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toFormat = format
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.toFormat.rawValue)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, -15) // Zwiększony ujemny padding top żeby zbliżyć do headerSection
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.06))
        )
        .padding(.horizontal, 16)
    }
    
    private var inputSection: some View {
        VStack(spacing: 6) {
            VStack(spacing: 4) {
                HStack {
                    Text("Enter Coordinates")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("Latitude")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(viewModel.getFormatLabel(for: viewModel.fromFormat, isLatitude: true))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Text("Longitude")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(viewModel.getFormatLabel(for: viewModel.fromFormat, isLatitude: false))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            HStack(spacing: 12) {
                CoordinateInputView(
                    coordinate: $viewModel.latitude,
                    format: viewModel.fromFormat,
                    isLatitude: true,
                    onFieldComplete: {
                        focusedOnLongitude = true
                        viewModel.convert()
                    }
                )
                
                CoordinateInputView(
                    coordinate: $viewModel.longitude,
                    format: viewModel.fromFormat,
                    isLatitude: false,
                    onFieldComplete: {
                        viewModel.convert()
                        hideKeyboard()
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.06))
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private var outputSection: some View {
        VStack(spacing: 6) {
            VStack(spacing: 4) {
                HStack {
                    Text("Output Coordinates")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("Latitude")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(viewModel.getFormatLabel(for: viewModel.toFormat, isLatitude: true))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Text("Longitude")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(viewModel.getFormatLabel(for: viewModel.toFormat, isLatitude: false))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            HStack(spacing: 12) {
                CoordinateDisplayView(
                    coordinate: viewModel.convertedLatitude,
                    format: viewModel.toFormat,
                    isLatitude: true
                )
                
                CoordinateDisplayView(
                    coordinate: viewModel.convertedLongitude,
                    format: viewModel.toFormat,
                    isLatitude: false
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.08))
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button(action: {
                    if let url = viewModel.getMapURL(service: .appleMaps) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "map.circle.fill")
                            .font(.subheadline)
                        Text("Apple Maps")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel("Open in Apple Maps")
                
                Button(action: {
                    if let url = viewModel.getMapURL(service: .googleMaps) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe.europe.africa.fill")
                            .font(.subheadline)
                        Text("Google Maps")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.green.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel("Open in Google Maps")
            }
            
            HStack(spacing: 10) {
                Button(action: {
                    let coordinates = viewModel.getFormattedCoordinatesString()
                    UIPasteboard.general.string = coordinates
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.subheadline)
                        Text("Copy")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.orange.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel("Copy coordinates to clipboard")
                
                Button(action: {
                    let coordinates = viewModel.getFormattedCoordinatesString()
                    shareToMessenger(coordinates: coordinates)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.subheadline)
                        Text("Share")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.purple.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel("Share coordinates")
            }
        }
        .padding(.horizontal, 16)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension ContentView {
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
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                          y: rootViewController.view.bounds.midY,
                                          width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityViewController, animated: true)
        }
    }
}