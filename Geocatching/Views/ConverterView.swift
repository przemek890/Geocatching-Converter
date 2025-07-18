import SwiftUI

struct ConverterView: View {
    @StateObject private var viewModel = CoordinateViewModel()
    @StateObject private var alphabetViewModel = AlphabetViewModel()
    @ObservedObject var settingsViewModel: SettingsViewModel

    @State private var showingImageViewer = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedLetter: String = ""

    @State private var latitudeInputID = UUID()
    @State private var longitudeInputID = UUID()

    private var alphabetLetters: [String] {
        let allLetters = alphabetViewModel.currentAlphabet
        let filtered = allLetters.filter { letter in
            let hasNumber = alphabetViewModel.letterNumbers[letter]?.isEmpty == false
            return hasNumber
        }
        return filtered
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    Spacer().frame(height: 20)
                    inputSection
                    Spacer().frame(height: 12)
                    outputSection
                    Spacer().frame(height: 16)
                    actionButtonsSection
                    Spacer().frame(height: 100)
                }
            }
            .scrollDisabled(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        clearFields()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Reset input coordinates")
                }
            }
            .navigationBarHidden(false)
            .onTapGesture {
                hideKeyboard()
            }
        }
        .onAppear {
            alphabetViewModel.loadLetterData()
            if let inputFormat = CoordinateFormat(rawValue: settingsViewModel.defaultInputFormat) {
                viewModel.fromFormat = inputFormat
            }
            if let outputFormat = CoordinateFormat(rawValue: settingsViewModel.defaultOutputFormat) {
                viewModel.toFormat = outputFormat
            }
            viewModel.convert()
        }
        .onChange(of: viewModel.fromFormat) { _ in
            viewModel.resetInput()
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
        .onChange(of: alphabetViewModel.letterNumbers) { _ in }
        .onChange(of: alphabetViewModel.letterImages) { _ in }
        .onChange(of: alphabetViewModel.selectedAlphabet) { _ in }
        .onChange(of: selectedLetter) { newLetter in
            guard !newLetter.isEmpty else { return }
            if let imageData = alphabetViewModel.letterImages[newLetter],
               let image = UIImage(data: imageData) {
                selectedImage = image
                showingImageViewer = true
            }
        }
        .sheet(isPresented: $showingImageViewer) {
            CustomImageViewerView(
                image: selectedImage,
                letter: selectedLetter,
                onDelete: {
                    alphabetViewModel.letterImages[selectedLetter] = nil
                    alphabetViewModel.saveLetterData()
                    showingImageViewer = false
                }
            )
        }
    }

    private var headerSection: some View {
        VStack(spacing: 1) {
            Image("app")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 75, height: 75)
                .cornerRadius(18)
                .shadow(color: .primary.opacity(0.2), radius: 3, x: 0, y: 2)

            Text("Geocatching")
                .font(.title2)
                .fontWeight(.bold)
            Text("Coordinate Converter")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !alphabetLetters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(alphabetLetters, id: \.self) { letter in
                            Button(action: {
                                selectedLetter = letter
                                if let imageData = alphabetViewModel.letterImages[letter],
                                   let image = UIImage(data: imageData) {
                                    selectedImage = image
                                    showingImageViewer = true
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(letter)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                    if let number = alphabetViewModel.letterNumbers[letter], !number.isEmpty {
                                        Text(number)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                    if alphabetViewModel.letterImages[letter] != nil {
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .frame(height: 50)
            } else {
                Text("No letters configured")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, -15)
    }

    private var inputSection: some View {
        VStack(spacing: 6) {
            VStack(spacing: 4) {
                HStack {
                    Text("Input Coordinates")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(viewModel.fromFormat.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("Latitude")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 4) {
                        Text("Longitude")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 4)
            }
            HStack(spacing: 12) {
                CoordinateInputView(
                    coordinate: $viewModel.latitude,
                    format: viewModel.fromFormat,
                    isLatitude: true,
                    onFieldComplete: {
                        viewModel.convert()
                    }
                )
                .id(latitudeInputID)
                CoordinateInputView(
                    coordinate: $viewModel.longitude,
                    format: viewModel.fromFormat,
                    isLatitude: false,
                    onFieldComplete: {
                        viewModel.convert()
                        hideKeyboard()
                    }
                )
                .id(longitudeInputID)
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
                    Text("\(viewModel.toFormat.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.1))
                        )
                }
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("Latitude")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 4) {
                        Text("Longitude")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 20)
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
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.08))
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var actionButtonsSection: some View {
        HStack {
            Button(action: {
                let service: MapService = settingsViewModel.defaultMapService == "google" ? .googleMaps : .appleMaps
                if let url = viewModel.getMapURL(service: service) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: settingsViewModel.defaultMapService == "google" ? "globe.europe.africa.fill" : "map.circle.fill")
                        .font(.system(size: 18))
                    Text("Maps")
                        .fontWeight(.semibold)
                }
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .accessibilityLabel("Open in Maps")
            Button(action: {
                let coordinates = viewModel.getFormattedCoordinatesString()
                shareToMessenger(coordinates: coordinates)
            }) {
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
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .accessibilityLabel("Share coordinates")
        }
        .padding(.horizontal, 16)
    }
}

extension ConverterView {
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                            y: rootViewController.view.bounds.midY,
                                            width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootViewController.present(activityViewController, animated: true)
        }
    }

    private func clearFields() {
        viewModel.latitude = Coordinate(direction: .north)
        viewModel.longitude = Coordinate(direction: .east)
        latitudeInputID = UUID()
        longitudeInputID = UUID()
        viewModel.convert()
    }
}
