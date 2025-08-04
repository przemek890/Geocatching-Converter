import SwiftUI

struct SnapshotsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    @ObservedObject var coordinateViewModel: CoordinateViewModel
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("currentSnapshotID") private var currentSnapshotID: String?
    @State private var newSnapshotName: String = ""
    @State private var showingSaveAlert = false
    @State private var showingEditAlert = false
    @State private var showingDeleteAlert = false
    @State private var selectedSnapshot: SettingsSnapshot? = nil
    
    var body: some View {
        NavigationView {
            List {
                let snapshots = settingsViewModel.getSnapshots()
                ForEach(snapshots) { snapshot in
                    snapshotRow(snapshot: snapshot)
                        .background(currentSnapshotID == snapshot.id ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Snapshots", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Create") {
                    newSnapshotName = ""
                    showingSaveAlert = true
                }
            )
            .alert("Save Snapshot", isPresented: $showingSaveAlert) {
                TextField("Enter snapshot name", text: $newSnapshotName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    if !newSnapshotName.isEmpty {
                        saveNewSnapshot(name: newSnapshotName)
                        newSnapshotName = ""
                    }
                }
            }
            .alert("Edit Snapshot Name", isPresented: $showingEditAlert) {
                TextField("New name", text: $newSnapshotName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    if let snapshot = selectedSnapshot, !newSnapshotName.isEmpty {
                        updateSnapshotName(snapshot, newName: newSnapshotName)
                        newSnapshotName = ""
                    }
                }
            }
            .alert("Delete Snapshot", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let snapshot = selectedSnapshot {
                        deleteSnapshot(snapshot)
                        selectedSnapshot = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this snapshot? This action cannot be undone.")
            }
        }
        .onAppear {
            initializeCurrentSnapshot()
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
            Button(action: {
                selectedSnapshot = snapshot
                showingEditAlert = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Button(action: {
                selectedSnapshot = snapshot
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            switchSnapshot(to: snapshot)
        }
    }
    
    private func initializeCurrentSnapshot() {
        let snapshots = settingsViewModel.getSnapshots()
        if currentSnapshotID == nil, let firstSnapshot = snapshots.first {
            currentSnapshotID = firstSnapshot.id
            Task {
                await loadSnapshot(
                    firstSnapshot,
                    settingsViewModel: settingsViewModel,
                    alphabetViewModel: alphabetViewModel,
                    coordinateViewModel: coordinateViewModel
                )
            }
        } else if snapshots.isEmpty {
            resetAllViews()
        }
    }
    
    private func switchSnapshot(to snapshot: SettingsSnapshot) {
        if let currentSnapshotID = currentSnapshotID,
           let currentSnapshot = settingsViewModel.getSnapshots().first(where: { $0.id == currentSnapshotID }) {
            saveSnapshotData(snapshot: currentSnapshot)
        }
        
        currentSnapshotID = snapshot.id
        
        Task {
            await loadSnapshot(
                snapshot,
                settingsViewModel: settingsViewModel,
                alphabetViewModel: alphabetViewModel,
                coordinateViewModel: coordinateViewModel
            )
        }
    }
    
    private func saveNewSnapshot(name: String) {
        if let currentSnapshotID = currentSnapshotID,
           let currentSnapshot = settingsViewModel.getSnapshots().first(where: { $0.id == currentSnapshotID }) {
            saveSnapshotData(snapshot: currentSnapshot)
        }

        let emptySettings: [String: Any] = [
            "isDarkMode": settingsViewModel.isDarkMode,
            "defaultInputFormat": settingsViewModel.defaultInputFormat,
            "defaultOutputFormat": settingsViewModel.defaultOutputFormat,
            "defaultMapService": settingsViewModel.defaultMapService,
            "lockDigits": settingsViewModel.lockDigits,
            "lockEnteredLetters": "",
            "letterNumbers": [String: String](),
            "letterImages": [String: String](),
            "selectedAlphabet": "english",
            "latitude": Coordinate(direction: .north).toString(),
            "longitude": Coordinate(direction: .east).toString(),
            "fromFormat": CoordinateFormat.ddm.rawValue,
            "toFormat": CoordinateFormat.dd.rawValue,
            "compassLetterInputs": "",
            "compassDistanceLetterInputs": "",
            "generalNote": ""
        ]
        
        guard let emptyData = try? JSONSerialization.data(withJSONObject: emptySettings, options: []) else { 
            return 
        }
        
        let newSnapshot = SettingsSnapshot(
            id: UUID().uuidString,
            name: name,
            date: Date(),
            data: emptyData
        )
        
        var snapshots = settingsViewModel.getSnapshots()
        snapshots.append(newSnapshot)
        if let encodedSnapshots = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(encodedSnapshots, forKey: "settings_snapshots")
        }
        
        clearAllAppDataForNewSnapshot()
        currentSnapshotID = newSnapshot.id
        
        Task {
            await loadSnapshot(
                newSnapshot,
                settingsViewModel: settingsViewModel,
                alphabetViewModel: alphabetViewModel,
                coordinateViewModel: coordinateViewModel
            )
        }
    }
    
    private func clearAllAppDataForNewSnapshot() {
        UserDefaults.standard.set("", forKey: "generalNote")
        alphabetViewModel.letterNumbers = [:]
        alphabetViewModel.letterImages = [:]
        alphabetViewModel.saveLetterData()
        alphabetViewModel.selectedAlphabet = "english"
        coordinateViewModel.latitude = Coordinate(direction: .north)
        coordinateViewModel.longitude = Coordinate(direction: .east)
        coordinateViewModel.convertedLatitude = Coordinate(direction: .north)
        coordinateViewModel.convertedLongitude = Coordinate(direction: .east)
        coordinateViewModel.fromFormat = .ddm
        coordinateViewModel.toFormat = .dd
        settingsViewModel.lockEnteredLetters = ""
        UserDefaults.standard.set("", forKey: "compassLetterInputs")
        UserDefaults.standard.set("", forKey: "compassDistanceLetterInputs")
    }
    
    private func saveSnapshotData(snapshot: SettingsSnapshot) {
        var settings: [String: Any] = [:]
        

        settings["isDarkMode"] = settingsViewModel.isDarkMode
        settings["defaultInputFormat"] = settingsViewModel.defaultInputFormat
        settings["defaultOutputFormat"] = settingsViewModel.defaultOutputFormat
        settings["defaultMapService"] = settingsViewModel.defaultMapService
        settings["lockDigits"] = settingsViewModel.lockDigits
        settings["lockEnteredLetters"] = settingsViewModel.lockEnteredLetters
        

        settings["letterNumbers"] = alphabetViewModel.letterNumbers
        settings["selectedAlphabet"] = alphabetViewModel.selectedAlphabet
        

        let encodedLetterImages = alphabetViewModel.letterImages.mapValues { $0.base64EncodedString() }
        settings["letterImages"] = encodedLetterImages
        
        settings["latitude"] = coordinateViewModel.latitude.toString()
        settings["longitude"] = coordinateViewModel.longitude.toString()
        settings["fromFormat"] = coordinateViewModel.fromFormat.rawValue
        settings["toFormat"] = coordinateViewModel.toFormat.rawValue
        
        settings["compassLetterInputs"] = UserDefaults.standard.string(forKey: "compassLetterInputs") ?? ""
        settings["compassDistanceLetterInputs"] = UserDefaults.standard.string(forKey: "compassDistanceLetterInputs") ?? ""
        
        settings["generalNote"] = UserDefaults.standard.string(forKey: "generalNote") ?? ""
        
        guard let encodedData = try? JSONSerialization.data(withJSONObject: settings, options: []) else {
            print("Failed to encode snapshot data")
            return
        }
        
        updateSnapshotData(snapshot: snapshot, data: encodedData)
    }
    
    private func updateSnapshotData(snapshot: SettingsSnapshot, data: Data) {
        var snapshots = settingsViewModel.getSnapshots()
        if let index = snapshots.firstIndex(where: { $0.id == snapshot.id }) {
            snapshots[index] = SettingsSnapshot(
                id: snapshot.id,
                name: snapshot.name,
                date: snapshot.date,
                data: data
            )
            if let encodedData = try? JSONEncoder().encode(snapshots) {
                UserDefaults.standard.set(encodedData, forKey: "settings_snapshots")
            }
        }
    }
    
    private func deleteSnapshot(_ snapshot: SettingsSnapshot) {
        var snapshots = settingsViewModel.getSnapshots()
        snapshots.removeAll { $0.id == snapshot.id }
        if let encodedData = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(encodedData, forKey: "settings_snapshots")
        }
        if let first = snapshots.first {
            currentSnapshotID = first.id
            Task {
                await loadSnapshot(
                    first,
                    settingsViewModel: settingsViewModel,
                    alphabetViewModel: alphabetViewModel,
                    coordinateViewModel: coordinateViewModel
                )
            }
        } else {
            currentSnapshotID = nil
            resetAllViews()
        }
    }
    
    private func updateSnapshotName(_ snapshot: SettingsSnapshot, newName: String) {
        var snapshots = settingsViewModel.getSnapshots()
        if let index = snapshots.firstIndex(where: { $0.id == snapshot.id }) {
            snapshots[index] = SettingsSnapshot(
                id: snapshot.id,
                name: newName,
                date: snapshot.date,
                data: snapshot.data
            )
            if let encodedData = try? JSONEncoder().encode(snapshots) {
                UserDefaults.standard.set(encodedData, forKey: "settings_snapshots")
            }
        }
    }
    
    private func createEmptySnapshot() {
        let defaultSettings = SettingsSnapshot(
            id: UUID().uuidString,
            name: "New Snapshot",
            date: Date(),
            data: Data()
        )
        
        var snapshots = settingsViewModel.getSnapshots()
        snapshots.append(defaultSettings)
        
        if let encodedSnapshots = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(encodedSnapshots, forKey: "settings_snapshots")
        }
        
        currentSnapshotID = defaultSettings.id
    }
    
    private func createEmptySnapshot(with name: String) {
        let emptySettings: [String: Any] = [
            "isDarkMode": false,
            "defaultInputFormat": CoordinateFormat.dd.rawValue,
            "defaultOutputFormat": CoordinateFormat.dms.rawValue,
            "defaultMapService": "apple",
            "lockDigits": 4,
            "lockEnteredLetters": "",
            "letterNumbers": [String: String](),
            "letterImages": [String: String](),
            "selectedAlphabet": "english",
            "latitude": "",
            "longitude": "",
            "compassLetterInputs": "",
            "compassDistanceLetterInputs": "",
            "generalNote": ""
        ]
        let data = (try? JSONSerialization.data(withJSONObject: emptySettings, options: [])) ?? Data()
        let snapshot = SettingsSnapshot(
            id: UUID().uuidString,
            name: name,
            date: Date(),
            data: data
        )
        var snapshots = settingsViewModel.getSnapshots()
        snapshots.append(snapshot)
        if let encodedSnapshots = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(encodedSnapshots, forKey: "settings_snapshots")
        }
        currentSnapshotID = snapshot.id
        resetAllViews()
    }
    
    private func resetAllViews() {
        settingsViewModel.lockEnteredLetters = ""
        coordinateViewModel.latitude = Coordinate(direction: .north)
        coordinateViewModel.longitude = Coordinate(direction: .east)
        coordinateViewModel.convertedLatitude = Coordinate(direction: .north)
        coordinateViewModel.convertedLongitude = Coordinate(direction: .east)
        coordinateViewModel.fromFormat = .ddm
        coordinateViewModel.toFormat = .dd
        UserDefaults.standard.set("", forKey: "compassLetterInputs")
        UserDefaults.standard.set("", forKey: "compassDistanceLetterInputs")
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

@MainActor
func loadSnapshot(_ snapshot: SettingsSnapshot, settingsViewModel: SettingsViewModel, alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
    guard let settings = try? JSONSerialization.jsonObject(with: snapshot.data, options: []) as? [String: Any] else {
        print("Failed to decode snapshot data")
        return
    }
    
    settingsViewModel.isDarkMode = settings["isDarkMode"] as? Bool ?? false
    settingsViewModel.defaultInputFormat = settings["defaultInputFormat"] as? String ?? CoordinateFormat.dd.rawValue
    settingsViewModel.defaultOutputFormat = settings["defaultOutputFormat"] as? String ?? CoordinateFormat.dms.rawValue
    settingsViewModel.defaultMapService = settings["defaultMapService"] as? String ?? "apple"
    settingsViewModel.lockDigits = settings["lockDigits"] as? Int ?? 4
    
    settingsViewModel.lockEnteredLetters = ""
    UserDefaults.standard.set("", forKey: "compassLetterInputs")
    UserDefaults.standard.set("", forKey: "compassDistanceLetterInputs")
    
    UserDefaults.standard.set("", forKey: "inputLatitude")
    UserDefaults.standard.set("", forKey: "inputLongitude")
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        let lockEnteredLetters = settings["lockEnteredLetters"] as? String ?? ""
        settingsViewModel.lockEnteredLetters = lockEnteredLetters
        
        NotificationCenter.default.post(
            name: Notification.Name("LockDataChanged"),
            object: nil,
            userInfo: ["letters": lockEnteredLetters]
        )
        
        UserDefaults.standard.set(settings["compassLetterInputs"] as? String ?? "", forKey: "compassLetterInputs")
        UserDefaults.standard.set(settings["compassDistanceLetterInputs"] as? String ?? "", forKey: "compassDistanceLetterInputs")
        NotificationCenter.default.post(name: Notification.Name("CompassDataChanged"), object: nil)
        
        if let latitudeString = settings["latitude"] as? String {
            if let lat = Coordinate.fromString(latitudeString, direction: .north) {
                coordinateViewModel.latitude = lat
                UserDefaults.standard.set(latitudeString, forKey: "inputLatitude")
            }
        }
        
        if let longitudeString = settings["longitude"] as? String {
            if let lon = Coordinate.fromString(longitudeString, direction: .east) {
                coordinateViewModel.longitude = lon
                UserDefaults.standard.set(longitudeString, forKey: "inputLongitude")
            }
        }
        
        if let fromFormat = settings["fromFormat"] as? String,
           let format = CoordinateFormat(rawValue: fromFormat) {
            coordinateViewModel.fromFormat = format
        }
        
        if let toFormat = settings["toFormat"] as? String,
           let format = CoordinateFormat(rawValue: toFormat) {
            coordinateViewModel.toFormat = format
        }

        coordinateViewModel.convert()
        
        NotificationCenter.default.post(name: Notification.Name("CoordinatesChanged"), object: nil)
    }
    
    let letterNumbers = settings["letterNumbers"] as? [String: String] ?? [:]
    let selectedAlphabet = settings["selectedAlphabet"] as? String ?? "english"
    
    var letterImages: [String: Data] = [:]
    if let encodedLetterImages = settings["letterImages"] as? [String: String] {
        letterImages = encodedLetterImages.compactMapValues { Data(base64Encoded: $0) }
    }
    
    alphabetViewModel.loadFromSnapshot(
        letterNumbers: letterNumbers,
        letterImages: letterImages,
        alphabet: selectedAlphabet
    )
    
    UserDefaults.standard.set("", forKey: "generalNote")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        UserDefaults.standard.set(settings["generalNote"] as? String ?? "", forKey: "generalNote")
    }
}