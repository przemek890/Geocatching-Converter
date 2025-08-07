import Foundation
import SwiftUI

@MainActor
class SnapshotViewModel: ObservableObject {
    @AppStorage("currentSnapshotID") private var currentSnapshotID: String?
    
    var currentID: String? {
        return currentSnapshotID
    }
    
    @Published var selectedSnapshot: SettingsSnapshot? = nil
    @Published var newSnapshotName: String = ""
    @Published var showingSaveAlert = false
    @Published var showingEditAlert = false
    @Published var showingDeleteAlert = false
    
    private let settingsViewModel: SettingsViewModel
    private let alphabetViewModel: AlphabetViewModel
    private let coordinateViewModel: CoordinateViewModel
    private let storageManager = SettingsStorageManager()
    
    init(settingsViewModel: SettingsViewModel, alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
        self.settingsViewModel = settingsViewModel
        self.alphabetViewModel = alphabetViewModel
        self.coordinateViewModel = coordinateViewModel
    }
    
    var snapshots: [SettingsSnapshot] {
        return settingsViewModel.getSnapshots()
    }
    
    func initializeCurrentSnapshot() {
        let availableSnapshots = snapshots
        
        if currentSnapshotID == nil, let firstSnapshot = availableSnapshots.first {
            currentSnapshotID = firstSnapshot.id
            Task {
                await loadSnapshot(firstSnapshot)
            }
        } else if availableSnapshots.isEmpty {
            resetAllViews()
        }
    }
    
    func switchSnapshot(to snapshot: SettingsSnapshot) {
        if let currentID = currentSnapshotID,
           let currentSnapshot = snapshots.first(where: { $0.id == currentID }) {
            saveSnapshotData(snapshot: currentSnapshot)
        }
        
        alphabetViewModel.letterNumbers.removeAll()
        alphabetViewModel.letterImages.removeAll()
        
        currentSnapshotID = snapshot.id
        
        NotificationCenter.default.post(
            name: Notification.Name("CurrentSnapshotChanged"),
            object: nil, 
            userInfo: ["snapshotID": snapshot.id]
        )
        
        Task {
            await loadSnapshot(snapshot)
        }
    }
    
    func createNewSnapshot(name: String) {
        if let currentID = currentSnapshotID,
           let currentSnapshot = snapshots.first(where: { $0.id == currentID }) {
            saveSnapshotData(snapshot: currentSnapshot)
        }

        let emptySettings = createEmptySettingsModel()
        guard let emptyData = storageManager.encodeSettingsModel(emptySettings) else { return }
        
        let newSnapshot = SettingsSnapshot(
            id: UUID().uuidString,
            name: name,
            date: Date(),
            data: emptyData
        )
        
        storageManager.saveSnapshot(newSnapshot)
        
        clearAllAppDataForNewSnapshot()
        currentSnapshotID = newSnapshot.id
        
        Task {
            await loadSnapshot(newSnapshot)
        }
    }
    
    func deleteCurrentSnapshot() {
        guard let snapshot = selectedSnapshot else { return }
        
        if snapshots.count <= 1 {
            return
        }
        
        if snapshot.id == currentSnapshotID {
            let remainingSnapshots = snapshots.filter { $0.id != snapshot.id }
            if let first = remainingSnapshots.first {
                currentSnapshotID = first.id
                Task {
                    await loadSnapshot(first)
                }
            } else {
                currentSnapshotID = nil
                resetAllViews()
            }
        }
        
        storageManager.deleteSnapshot(snapshot)
    }
    
    func updateSnapshotName(newName: String) {
        guard let snapshot = selectedSnapshot, !newName.isEmpty else { return }
        
        let updatedSnapshot = SettingsSnapshot(
            id: snapshot.id,
            name: newName,
            date: snapshot.date,
            data: snapshot.data
        )
        
        storageManager.updateSnapshot(updatedSnapshot)
    }
    
    private func loadSnapshot(_ snapshot: SettingsSnapshot) async {
        settingsViewModel.loadSnapshot(
            snapshot,
            alphabetViewModel: alphabetViewModel,
            coordinateViewModel: coordinateViewModel
        )
        DispatchQueue.main.async {
            self.settingsViewModel.objectWillChange.send()
        }
    }
    
    private func createSettingsModelFromCurrentState() -> SettingsModel {
        let encodedLetterImages = alphabetViewModel.letterImages.mapValues { $0.base64EncodedString() }
        
        let compassLetterInputs = settingsViewModel.getCurrentCompassLetterInputs()
        let compassDistanceInputs = settingsViewModel.getCurrentCompassDistanceInputs()
        
        return SettingsModel(
            isDarkMode: settingsViewModel.isDarkMode,
            defaultInputFormat: settingsViewModel.defaultInputFormat,
            defaultOutputFormat: settingsViewModel.defaultOutputFormat,
            defaultMapService: settingsViewModel.defaultMapService,
            lockDigits: settingsViewModel.lockDigits,
            lockEnteredLetters: settingsViewModel.lockEnteredLetters,
            letterNumbers: alphabetViewModel.letterNumbers,
            selectedAlphabet: alphabetViewModel.selectedAlphabet,
            letterImages: encodedLetterImages,
            compassLetterInputs: compassLetterInputs,
            compassDistanceLetterInputs: compassDistanceInputs,
            generalNote: UserDefaults.standard.string(forKey: "generalNote") ?? "",
            latitude: coordinateViewModel.latitude.toString(),
            longitude: coordinateViewModel.longitude.toString(),
            fromFormat: coordinateViewModel.fromFormat.rawValue,
            toFormat: coordinateViewModel.toFormat.rawValue
        )
    }
    
    private func saveSnapshotData(snapshot: SettingsSnapshot) {
        let settingsModel = createSettingsModelFromCurrentState()
        
        guard let encodedData = storageManager.encodeSettingsModel(settingsModel) else { return }
        
        let updatedSnapshot = SettingsSnapshot(
            id: snapshot.id,
            name: snapshot.name,
            date: snapshot.date,
            data: encodedData
        )
        
        storageManager.updateSnapshot(updatedSnapshot)
    }
    
    private func createEmptySettingsModel() -> SettingsModel {
        return SettingsModel.default
    }
    
    private func clearAllAppDataForNewSnapshot() {
        UserDefaults.standard.set("", forKey: "generalNote")
        alphabetViewModel.letterNumbers = [:]
        alphabetViewModel.letterImages = [:]
        if let actualSnapshotID = currentSnapshotID {
            alphabetViewModel.saveLetterData(forSnapshotID: actualSnapshotID)
        }
        alphabetViewModel.selectedAlphabet = "english"
        coordinateViewModel.latitude = Coordinate(direction: .north)
        coordinateViewModel.longitude = Coordinate(direction: .east)
        coordinateViewModel.convertedLatitude = Coordinate(direction: .north)
        coordinateViewModel.convertedLongitude = Coordinate(direction: .east)
        coordinateViewModel.fromFormat = .ddm
        coordinateViewModel.toFormat = .dd
        settingsViewModel.lockEnteredLetters = ""
        
        NotificationCenter.default.post(
            name: Notification.Name("CompassDataReset"),
            object: nil,
            userInfo: ["snapshotID": currentSnapshotID ?? ""]
        )
    }
    
    private func resetAllViews() {
        settingsViewModel.lockEnteredLetters = ""
        coordinateViewModel.latitude = Coordinate(direction: .north)
        coordinateViewModel.longitude = Coordinate(direction: .east)
        coordinateViewModel.convertedLatitude = Coordinate(direction: .north)
        coordinateViewModel.convertedLongitude = Coordinate(direction: .east)
        coordinateViewModel.fromFormat = .ddm
        coordinateViewModel.toFormat = .dd
        
        NotificationCenter.default.post(
            name: Notification.Name("CompassDataReset"),
            object: nil,
            userInfo: ["snapshotID": currentSnapshotID ?? ""]
        )
    }
}