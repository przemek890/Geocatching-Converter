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
                    NotesSettingsSection()
                    
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
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Settings")
            }
            .preferredColorScheme(settingsViewModel.isDarkMode ? .dark : .light)
        }
    }
}