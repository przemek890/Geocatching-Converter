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
    @State private var showingLoadAlert = false
    @State private var showingDeleteAlert = false

    var body: some View {
        DisclosureGroup("History") {
            VStack(spacing: 10) {
                ForEach(settingsViewModel.getSavedSettingsNames(), id: \.self) { name in
                    HStack {
                        Text(name)
                            .font(.system(.body, design: .rounded))
                        
                        Spacer()
                        
                        Button(action: {
                            selectedHistoryName = name
                            showingLoadAlert = true
                        }) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button(action: {
                            selectedHistoryName = name
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 4)
                }

                Divider()
                
                Button(action: {
                    showingSaveAlert = true
                }) {
                    Label("Save Current Settings", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .alert("Save Settings", isPresented: $showingSaveAlert) {
                    TextField("Name", text: $newHistoryName)
                    Button("Cancel", role: .cancel) { }
                    Button("Save") {
                        if !newHistoryName.isEmpty {
                            settingsViewModel.saveCurrentSettings(
                                as: newHistoryName,
                                alphabetViewModel: alphabetViewModel,
                                coordinateViewModel: coordinateViewModel
                            )
                            newHistoryName = ""
                        }
                    }
                } message: {
                    Text("Enter a name for these settings")
                }
                .alert("Load Settings", isPresented: $showingLoadAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Load") {
                        if let name = selectedHistoryName {
                            settingsViewModel.loadSettings(
                                from: name,
                                alphabetViewModel: alphabetViewModel,
                                coordinateViewModel: coordinateViewModel
                            )
                        }
                    }
                } message: {
                    if let name = selectedHistoryName {
                        Text("Load settings from '\(name)'? This will replace your current settings.")
                    }
                }
                .alert("Delete Settings", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let name = selectedHistoryName {
                            settingsViewModel.deleteSettings(withName: name)
                        }
                    }
                } message: {
                    if let name = selectedHistoryName {
                        Text("Are you sure you want to delete '\(name)'?")
                    }
                }
            }
        }
    }
}