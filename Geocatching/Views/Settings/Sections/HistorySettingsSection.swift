import SwiftUI

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
                ForEach(settingsViewModel.getSnapshots(), id: \.id) { snapshot in
                    HStack {
                        Text(snapshot.name)
                            .font(.system(.body, design: .rounded))
                        
                        Spacer()
                        
                        Button(action: {
                            selectedHistoryName = snapshot.name
                            showingLoadAlert = true
                        }) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        if settingsViewModel.getSnapshots().count > 1 {
                            Button(action: {
                                selectedHistoryName = snapshot.name
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
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
                            if let snapshot = settingsViewModel.getSnapshots().first(where: { $0.name == name }) {
                                Task {
                                    settingsViewModel.loadSnapshot(
                                        snapshot,
                                        alphabetViewModel: alphabetViewModel,
                                        coordinateViewModel: coordinateViewModel
                                    )
                                }
                            }
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
                            if settingsViewModel.getSnapshots().contains(where: { $0.name == name }) {
                                settingsViewModel.deleteSettings(withName: name)
                            }
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