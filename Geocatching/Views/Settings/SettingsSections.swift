import SwiftUI

struct AlphabetConfigItem: Identifiable {
    let id = UUID()
    let alphabet: String
}

struct AlphabetSettingsSection: View {
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    @State private var alphabetConfigItem: AlphabetConfigItem? = nil
    @State private var showingResetAlert = false
    @State private var hasAppeared = false

    var body: some View {
        Section(header: Text("Alphabet Coding")) {
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Alphabet Type")
                Spacer()
                Menu {
                    Button("English") {
                        alphabetViewModel.setAlphabetType(type: "english")
                    }
                    Button("Polish") {
                        alphabetViewModel.setAlphabetType(type: "polish")
                    }
                } label: {
                    Text(alphabetViewModel.selectedAlphabet == "polish" ? "Polish" : "English")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 5)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            Button(action: {
                showingResetAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                        .font(.system(size: 16))
                    Text("Reset")
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
        .onAppear {
            hasAppeared = true
        }
        .sheet(item: $alphabetConfigItem) { item in
            NavigationStack {
                AlphabetConfigView(
                    alphabet: alphabetViewModel.currentAlphabet,
                    letterNumbers: Binding(
                        get: { alphabetViewModel.letterNumbers },
                        set: { alphabetViewModel.letterNumbers = $0 }
                    ),
                    letterImages: Binding(
                        get: { alphabetViewModel.letterImages },
                        set: { alphabetViewModel.letterImages = $0 }
                    ),
                    onSave: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            alphabetViewModel.saveLetterData()
                            alphabetConfigItem = nil
                        }
                    }
                )
                .navigationTitle("Configure Alphabet")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            alphabetConfigItem = nil
                        }
                    }
                }
            }
        }
        .alert("Reset All Letters", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                alphabetViewModel.resetAllLetters()
            }
        } message: {
            Text("Are you sure you want to delete all assigned numbers and photos? This action cannot be undone.")
        }
    }
}

struct GeneralSettingsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(header: Text("General Settings")) {
            HStack {
                Image(systemName: viewModel.isDarkMode ? "moon.fill" : "sun.max.fill")
                    .foregroundColor(viewModel.isDarkMode ? .blue : .orange)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Dark Mode")
                    .font(.body)
                Spacer()
                Toggle("", isOn: $viewModel.isDarkMode)
            }
            .padding(.vertical, 4)

            NotesSettingsSection()
        }
    }
}

struct FormatSettingsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(header: Text("Coordinate Formats")) {
            HStack {
                Image(systemName: "arrow.down.doc.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Input Format")
                Spacer()
                Menu {
                    ForEach(CoordinateFormat.allCases, id: \.self) { format in
                        Button(format.displayName) {
                            viewModel.setInputFormat(format)
                        }
                    }
                } label: {
                    Text(CoordinateFormat(rawValue: viewModel.defaultInputFormat)?.rawValue ?? "DD")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 5)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            HStack {
                Image(systemName: "arrow.up.doc.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Output Format")
                Spacer()
                Menu {
                    ForEach(CoordinateFormat.allCases, id: \.self) { format in
                        Button(format.displayName) {
                            viewModel.setOutputFormat(format)
                        }
                    }
                } label: {
                    Text(CoordinateFormat(rawValue: viewModel.defaultOutputFormat)?.rawValue ?? "DMS")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 5)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Default Maps")
                Spacer()
                Menu {
                    Button("Apple Maps") { viewModel.setMapService("apple") }
                    Button("Google Maps") { viewModel.setMapService("google") }
                } label: {
                    Text(viewModel.defaultMapService == "google" ? "Google" : "Apple")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 5)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct LockSettingsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(header: Text("Lock Settings")) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Lock Digits")
                Spacer()
                Text("\(viewModel.lockDigits)")
                    .foregroundColor(.secondary)
                    .font(.body)
                Stepper("", value: Binding(
                    get: { viewModel.lockDigits },
                    set: { viewModel.setLockDigits($0) }
                ), in: 3...10)
                .labelsHidden()
            }
            .padding(.vertical, 4)
        }
    }
}

struct AppInfoSection: View {
    var body: some View {
        Section {
            VStack(spacing: 0) {
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
            .padding(.top, -25)
        }
    }
}
