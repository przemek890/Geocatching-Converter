import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var alphabetViewModel = AlphabetViewModel()
    @StateObject private var coordinateViewModel = CoordinateViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ConverterView(settingsViewModel: settingsViewModel, coordinateViewModel: coordinateViewModel, alphabetViewModel: alphabetViewModel)
                .tabItem {
                    Image(systemName: "location.viewfinder")
                    Text("Converter")
                }
                .tag(0)
            
            LockView(alphabetViewModel: alphabetViewModel, settingsViewModel: settingsViewModel)
                .tabItem {
                    Image(systemName: "lock.fill")
                    Text("Lock")
                }
                .tag(1)
                
            CompassView(alphabetViewModel: alphabetViewModel, settingsViewModel: settingsViewModel)
                .tabItem {
                    Image(systemName: "location.north.line")
                    Text("Compass")
                }
                .tag(2)
                
            AlphabetConfigTabView(
                alphabetViewModel: alphabetViewModel,
                snapshotID: settingsViewModel.currentSnapshotID ?? ""
            )
                .tabItem {
                    Image(systemName: "textformat.abc")
                    Text("Alphabet")
                }
                .tag(3)
                
            SettingsView(
                settingsViewModel: settingsViewModel,
                alphabetViewModel: alphabetViewModel,
                coordinateViewModel: coordinateViewModel
            )
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}