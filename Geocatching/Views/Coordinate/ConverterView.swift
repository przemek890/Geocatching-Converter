import SwiftUI

struct ConverterView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var coordinateViewModel: CoordinateViewModel
    @ObservedObject var alphabetViewModel: AlphabetViewModel

    @State private var selectedLetter: String = ""

    @State private var latitudeInputID = UUID()
    @State private var longitudeInputID = UUID()
    @State private var showingClearConfirmation = false
    @State private var imageCache: [String: UIImage] = [:]
    @State private var showingImageViewer = false
    @State private var viewRefreshTrigger = false

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
                    headerView
                    Spacer().frame(height: 20)
                    inputSectionView
                    Spacer().frame(height: 12)
                    outputSectionView
                    Spacer().frame(height: 16)
                    actionButtonsView
                    Spacer().frame(height: 100)
                }
            }
            .scrollDisabled(true)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onTapGesture {
                hideKeyboard()
            }
        }
        .alert(isPresented: $showingClearConfirmation) {
            clearConfirmationAlert
        }
        .onAppear {
            precacheImages()
            setupOnAppear()
        }
        .onChange(of: coordinateViewModel.fromFormat) {
            coordinateViewModel.convert()
        }
        .onChange(of: coordinateViewModel.toFormat) {
            withAnimation(.easeInOut(duration: 0.2)) {
            coordinateViewModel.convert()
            }
        }
        .sheet(isPresented: $showingImageViewer) {
            Group {
                if let cachedImage = imageCache[selectedLetter] {
                    CustomImageViewer(
                        image: cachedImage,
                        letter: selectedLetter,
                        showTrashIcon: false,
                        onDelete: {
                            alphabetViewModel.letterImages[selectedLetter] = nil
                            imageCache.removeValue(forKey: selectedLetter)
                            if let actualSnapshotID = settingsViewModel.currentSnapshotID {
                                alphabetViewModel.saveLetterData(forSnapshotID: actualSnapshotID)
                            }
                            showingImageViewer = false
                        }
                    )
                } else {
                    ProgressView("Loading...")
                        .onAppear {
                            loadImageForLetter(selectedLetter)
                        }
                }
            }
            .id(viewRefreshTrigger)
        }
    }
}

private extension ConverterView {
    
    var headerView: some View {
        VStack(spacing: 0) {
            navigationHeader
            Spacer().frame(height: 20)
            appInfoSection
            alphabetScrollView
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, -15)
    }
    
    var navigationHeader: some View {
        ZStack {
            Text("Converter")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.top, 20)
                .padding(.bottom, 10)

            HStack {
                Spacer()
                Button(action: {
                    showingClearConfirmation = true
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                }
                .padding(.trailing, 28)
            }
        }
    }
    
    var appInfoSection: some View {
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
        }
    }
    
    var alphabetScrollView: some View {
        Group {
            if !alphabetLetters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(alphabetLetters, id: \.self) { letter in
                            LetterButtonView(
                                letter: letter,
                                number: alphabetViewModel.letterNumbers[letter],
                                hasImage: alphabetViewModel.letterImages[letter] != nil
                            ) {
                                handleLetterSelection(letter: letter)
                            }
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
    }

    var inputSectionView: some View {
        CoordinateInputSectionView(
            title: "Input Coordinates",
            format: coordinateViewModel.fromFormat,
            latitude: $coordinateViewModel.latitude,
            longitude: $coordinateViewModel.longitude,
            latitudeInputID: latitudeInputID,
            longitudeInputID: longitudeInputID,
            onFieldComplete: {
                coordinateViewModel.convert()
            }
        )
    }

    var outputSectionView: some View {
        CoordinateOutputSectionView(
            title: "Output Coordinates",
            format: coordinateViewModel.toFormat,
            latitude: coordinateViewModel.convertedLatitude,
            longitude: coordinateViewModel.convertedLongitude
        )
    }

    var actionButtonsView: some View {
        ActionButtonsView(
            coordinateViewModel: coordinateViewModel,
            settingsViewModel: settingsViewModel
        )
    }
    
    var clearConfirmationAlert: Alert {
        Alert(
            title: Text("Clear all inputs?"),
            message: Text("All entered data will be cleared."),
            primaryButton: .destructive(Text("Yes")) {
                clearFields()
            },
            secondaryButton: .cancel(Text("Cancel"))
        )
    }
}

private extension ConverterView {
    
    func precacheImages() {
        for letter in alphabetLetters {
            loadImageForLetter(letter)
        }
    }
    
    func loadImageForLetter(_ letter: String) {
        if let data = alphabetViewModel.letterImages[letter],
           let img = UIImage(data: data), 
           img.size.width > 0 && img.size.height > 0 {
            imageCache[letter] = img
            viewRefreshTrigger.toggle()
        }
    }
    
    func setupOnAppear() {
        if let aktualnySnapshotID = settingsViewModel.currentSnapshotID {
            alphabetViewModel.loadLetterData(forSnapshotID: aktualnySnapshotID)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                precacheImages()
            }
        }
        
        if let inputFormat = CoordinateFormat(rawValue: settingsViewModel.defaultInputFormat) {
            coordinateViewModel.fromFormat = inputFormat
        }
        if let outputFormat = CoordinateFormat(rawValue: settingsViewModel.defaultOutputFormat) {
            coordinateViewModel.toFormat = outputFormat
        }
        coordinateViewModel.convert()
    }
    
    func handleLetterSelection(letter: String) {
        selectedLetter = letter
        
        if alphabetViewModel.letterImages[letter] != nil {
            if imageCache[letter] == nil {
                loadImageForLetter(letter)
            }
            showingImageViewer = true
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func clearFields() {
        coordinateViewModel.resetInput()
        latitudeInputID = UUID()
        longitudeInputID = UUID()
    }
}
