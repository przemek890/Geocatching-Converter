import SwiftUI

struct AlphabetConfigItem: Identifiable {
    let id = UUID()
    let alphabet: String
}

struct AlphabetSettingsSection: View {
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var coordinateViewModel: CoordinateViewModel
    @State private var alphabetConfigItem: AlphabetConfigItem? = nil
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
                        if let snapshotID = settingsViewModel.currentSnapshotID {
                            alphabetViewModel.setAlphabetType(type: "english", snapshotID: snapshotID)
                        }
                    }
                    Button("Polish") {
                        if let snapshotID = settingsViewModel.currentSnapshotID {
                            alphabetViewModel.setAlphabetType(type: "polish", snapshotID: snapshotID)
                        }
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
                        if let actualSnapshotID = settingsViewModel.currentSnapshotID {
                            alphabetViewModel.saveLetterData(forSnapshotID: actualSnapshotID)
                        }
                        alphabetConfigItem = nil
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
    }
}