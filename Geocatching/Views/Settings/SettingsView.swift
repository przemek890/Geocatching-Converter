import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                List {
                    GeneralSettingsSection(viewModel: settingsViewModel)
                    
                    FormatSettingsSection(viewModel: settingsViewModel)
                    
                    LockSettingsSection(viewModel: settingsViewModel)
                    
                    AlphabetSettingsSection(alphabetViewModel: alphabetViewModel)
                    
                    AppInfoSection()
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarHidden(true)
            .preferredColorScheme(settingsViewModel.isDarkMode ? .dark : .light)
        }
    }
}
