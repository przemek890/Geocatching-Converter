import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    @ObservedObject var coordinateViewModel: CoordinateViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    GeneralSettingsSection(
                        settingsViewModel: settingsViewModel,
                        alphabetViewModel: alphabetViewModel,
                        coordinateViewModel: coordinateViewModel
                    )
                    
                    FormatSettingsSection(viewModel: settingsViewModel)
                    
                    LockSettingsSection(viewModel: settingsViewModel)

                    AlphabetSettingsSection(
                        alphabetViewModel: alphabetViewModel,
                        settingsViewModel: settingsViewModel,
                        coordinateViewModel: coordinateViewModel
                    )
                    
                    AppInfoSection()
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Settings")
            }
            .navigationBarHidden(true)
            .preferredColorScheme(settingsViewModel.isDarkMode ? .dark : .light)
        }
    }
}

struct HistorySettingsSection: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    @ObservedObject var coordinateViewModel: CoordinateViewModel
    @State private var newHistoryName: String = ""
    @State private var showingSaveAlert = false
    @State private var selectedHistoryName: String?

    var body: some View {
        DisclosureGroup("History") {
            VStack(spacing: 10) {
                ForEach(settingsViewModel.getSavedSettingsNames(), id: \.self) { name in
                    HStack {
                        Text(name)
                            .font(.body)
                        Spacer()
                        Button("Load") {
                            settingsViewModel.loadSettings(from: name, alphabetViewModel: alphabetViewModel, coordinateViewModel: coordinateViewModel)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }

                Divider()
                
                Button("Create Snapshot") {
                    showingSaveAlert = true
                }
                .alert("Save Settings", isPresented: $showingSaveAlert) {
                    TextField("Enter name", text: $newHistoryName)
                    Button("Cancel", role: .cancel) {}
                    Button("Save") {
                        settingsViewModel.saveCurrentSettings(as: newHistoryName, alphabetViewModel: alphabetViewModel, coordinateViewModel: coordinateViewModel)
                    }
                }
            }
        }
    }
}
