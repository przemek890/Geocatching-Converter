import SwiftUI

struct SnapshotsView: View {
    @StateObject var viewModel: SnapshotViewModel
    @Environment(\.dismiss) var dismiss
    
    init(settingsViewModel: SettingsViewModel, alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
        _viewModel = StateObject(wrappedValue: SnapshotViewModel(
            settingsViewModel: settingsViewModel,
            alphabetViewModel: alphabetViewModel,
            coordinateViewModel: coordinateViewModel
        ))
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.snapshots) { snapshot in
                    snapshotRow(snapshot: snapshot)
                        .background(backgroundColorFor(snapshot: snapshot))
                        .cornerRadius(8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Snapshots", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.newSnapshotName = ""
                        viewModel.showingSaveAlert = true
                    }
                }
            }
            .alert("Save Snapshot", isPresented: $viewModel.showingSaveAlert) {
                alertContent(for: .save)
            }
            .alert("Edit Snapshot Name", isPresented: $viewModel.showingEditAlert) {
                alertContent(for: .edit)
            }
            .alert("Delete Snapshot", isPresented: $viewModel.showingDeleteAlert) {
                alertContent(for: .delete)
            } message: {
                Text("Are you sure you want to delete this snapshot? This action cannot be undone.")
            }
        }
        .onAppear {
            viewModel.initializeCurrentSnapshot()
        }
    }
    
    private func backgroundColorFor(snapshot: SettingsSnapshot) -> Color {
        return viewModel.currentID == snapshot.id ? Color.blue.opacity(0.1) : Color.clear
    }
    
    private enum AlertType {
        case save, edit, delete
    }
    
    @ViewBuilder
    private func alertContent(for type: AlertType) -> some View {
        switch type {
        case .save:
            TextField("Enter snapshot name", text: $viewModel.newSnapshotName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if !viewModel.newSnapshotName.isEmpty {
                    viewModel.createNewSnapshot(name: viewModel.newSnapshotName)
                    viewModel.newSnapshotName = ""
                }
            }
        case .edit:
            TextField("New name", text: $viewModel.newSnapshotName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                viewModel.updateSnapshotName(newName: viewModel.newSnapshotName)
                viewModel.newSnapshotName = ""
            }
        case .delete:
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteCurrentSnapshot()
            }
        }
    }
    
    @ViewBuilder
    private func snapshotRow(snapshot: SettingsSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.name)
                    .font(.headline)
                Text(snapshot.date, formatter: dateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            HStack {
                Button(action: {
                    viewModel.selectedSnapshot = snapshot
                    viewModel.newSnapshotName = snapshot.name
                    viewModel.showingEditAlert = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                if viewModel.snapshots.count > 1 {
                    Button(action: {
                        viewModel.selectedSnapshot = snapshot
                        viewModel.showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.switchSnapshot(to: snapshot)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}