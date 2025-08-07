import SwiftUI

struct GeneralSettingsSection: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    @ObservedObject var coordinateViewModel: CoordinateViewModel
    @State private var showingSnapshotsView = false

    var body: some View {
        Section(header: Text("General")) {
            HStack {
                Image(systemName: settingsViewModel.isDarkMode ? "moon.fill" : "sun.max.fill")
                    .foregroundColor(settingsViewModel.isDarkMode ? .blue : .orange)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Dark Mode")
                    .font(.body)
                Spacer()
                Toggle("", isOn: $settingsViewModel.isDarkMode)
            }
            .padding(.vertical, 4)

            Button {
                showingSnapshotsView = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                        .font(.system(size: 16))
                    Text("Manage Snapshots")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
            .sheet(isPresented: $showingSnapshotsView) {
                SnapshotsView(
                    settingsViewModel: settingsViewModel,
                    alphabetViewModel: alphabetViewModel,
                    coordinateViewModel: coordinateViewModel
                )
            }
        }
    }
}