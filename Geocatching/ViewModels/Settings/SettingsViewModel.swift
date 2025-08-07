import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("defaultInputFormat") var defaultInputFormat = CoordinateFormat.dd.rawValue
    @AppStorage("defaultOutputFormat") var defaultOutputFormat = CoordinateFormat.dms.rawValue
    @AppStorage("defaultMapService") var defaultMapService = "apple"
    @AppStorage("lockDigits") var lockDigits = 4
    @AppStorage("lockEnteredLetters") var lockEnteredLetters: String = ""
    @AppStorage("currentSnapshotID") var currentSnapshotID: String?
    
    private let storageManager = SettingsStorageManager()
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCompassDataChanged),
            name: Notification.Name("CompassDataChanged"),
            object: nil
        )
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
    }
    
    func setInputFormat(_ format: CoordinateFormat) {
        defaultInputFormat = format.rawValue
    }
    
    func setOutputFormat(_ format: CoordinateFormat) {
        defaultOutputFormat = format.rawValue
    }
    
    func setMapService(_ service: String) {
        defaultMapService = service
    }
    
    func setLockDigits(_ digits: Int) {
        lockDigits = digits
        NotificationCenter.default.post(name: Notification.Name("LockDigitsChanged"), object: nil)
    }
    
    func getSnapshots() -> [SettingsSnapshot] {
        return storageManager.getSnapshots()
    }
    
    @MainActor
    func loadSnapshot(_ snapshot: SettingsSnapshot, alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
        guard let settingsModel = storageManager.decodeSettingsModel(from: snapshot.data) else {
            return
        }
        
        applySettings(settingsModel, to: alphabetViewModel, coordinateViewModel: coordinateViewModel)
    }
    
    func deleteSettings(withName name: String) {
        let snapshots = getSnapshots()
        
        if snapshots.count <= 1 {
            return
        }
        
        if let snapshotToDelete = snapshots.first(where: { $0.name == name }) {
            storageManager.deleteSnapshot(snapshotToDelete)
            objectWillChange.send()
        }
    }
    
    @MainActor
    func saveCurrentSettings(as name: String, alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
        let settingsModel = createCurrentSettingsModel(alphabetViewModel: alphabetViewModel, coordinateViewModel: coordinateViewModel)
        
        guard let data = storageManager.encodeSettingsModel(settingsModel) else { return }
        
        let snapshot = SettingsSnapshot(
            id: UUID().uuidString,
            name: name,
            date: Date(),
            data: data
        )
        
        storageManager.saveSnapshot(snapshot)
    }
    
    @MainActor
    func resetCurrentSnapshot(alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
        isDarkMode = false
        defaultInputFormat = CoordinateFormat.dd.rawValue
        defaultOutputFormat = CoordinateFormat.dms.rawValue
        defaultMapService = "apple"
        lockDigits = 4
        lockEnteredLetters = ""

        alphabetViewModel.letterNumbers = [:]
        alphabetViewModel.letterImages = [:]
        alphabetViewModel.selectedAlphabet = "english"
        if let actualSnapshotID = currentSnapshotID {
            alphabetViewModel.saveLetterData(forSnapshotID: actualSnapshotID)
        }

        coordinateViewModel.resetInput()

        UserDefaults.standard.set("", forKey: "generalNote")
        
        NotificationCenter.default.post(
            name: Notification.Name("CompassDataReset"),
            object: nil,
            userInfo: ["snapshotID": currentSnapshotID ?? ""]
        )
    }
    
    @MainActor
    private func createCurrentSettingsModel(alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) -> SettingsModel {
        let encodedLetterImages = alphabetViewModel.letterImages.mapValues { $0.base64EncodedString() }
        
        let compassLetterInputs = getCurrentCompassLetterInputs()
        let compassDistanceInputs = getCurrentCompassDistanceInputs()
        
        print("Creating model for snapshot \(currentSnapshotID ?? "nil"): letters=\(compassLetterInputs), distances=\(compassDistanceInputs)")
        
        return SettingsModel(
            isDarkMode: isDarkMode,
            defaultInputFormat: defaultInputFormat,
            defaultOutputFormat: defaultOutputFormat,
            defaultMapService: defaultMapService,
            lockDigits: lockDigits,
            lockEnteredLetters: lockEnteredLetters,
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
    
    @MainActor
    private func applySettings(_ settings: SettingsModel, to alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
        isDarkMode = settings.isDarkMode
        defaultInputFormat = settings.defaultInputFormat
        defaultOutputFormat = settings.defaultOutputFormat
        defaultMapService = settings.defaultMapService
        lockDigits = settings.lockDigits
        
        alphabetViewModel.letterNumbers = settings.letterNumbers
        alphabetViewModel.selectedAlphabet = settings.selectedAlphabet
        
        if !settings.letterImages.isEmpty {
            alphabetViewModel.letterImages = settings.letterImages.compactMapValues { Data(base64Encoded: $0) }
        }
        
        if let snapshotID = currentSnapshotID {
            alphabetViewModel.saveLetterData(forSnapshotID: snapshotID)
        }
        
        if let latitudeString = settings.latitude,
           let lat = Coordinate.fromString(latitudeString, direction: .north) {
            coordinateViewModel.latitude = lat
            UserDefaults.standard.set(latitudeString, forKey: "inputLatitude")
        }
        
        if let longitudeString = settings.longitude,
           let lon = Coordinate.fromString(longitudeString, direction: .east) {
            coordinateViewModel.longitude = lon
            UserDefaults.standard.set(longitudeString, forKey: "inputLongitude")
        }
        
        if let fromFormatString = settings.fromFormat,
           let format = CoordinateFormat(rawValue: fromFormatString) {
            coordinateViewModel.fromFormat = format
        }
        
        if let toFormatString = settings.toFormat,
           let format = CoordinateFormat(rawValue: toFormatString) {
            coordinateViewModel.toFormat = format
        }
        
        UserDefaults.standard.set(settings.generalNote, forKey: "generalNote")
        
        currentCompassLetterInputs = settings.compassLetterInputs
        currentCompassDistanceInputs = settings.compassDistanceLetterInputs
        
        coordinateViewModel.convert()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lockEnteredLetters = settings.lockEnteredLetters
            NotificationCenter.default.post(
                name: Notification.Name("LockDataChanged"),
                object: nil,
                userInfo: ["letters": settings.lockEnteredLetters]
            )
            NotificationCenter.default.post(name: Notification.Name("CoordinatesChanged"), object: nil)
            NotificationCenter.default.post(
                name: Notification.Name("CurrentSnapshotChanged"),
                object: nil,
                userInfo: [
                    "snapshotID": self.currentSnapshotID ?? "",
                    "compassLetterInputs": settings.compassLetterInputs,
                    "compassDistanceInputs": settings.compassDistanceLetterInputs
                ]
            )
        }
    }
    
    private var currentCompassLetterInputs: [String] = ["", "", ""]
    private var currentCompassDistanceInputs: [String] = ["", "", ""]

    func getCurrentCompassLetterInputs() -> [String] {
        return currentCompassLetterInputs
    }
    
    func getCurrentCompassDistanceInputs() -> [String] {
        return currentCompassDistanceInputs
    }
    
    @objc private func handleCompassDataChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let letterInputs = userInfo["letterInputs"] as? [String],
              let distanceInputs = userInfo["distanceInputs"] as? [String],
              let snapshotID = userInfo["snapshotID"] as? String,
              let snapshot = getSnapshots().first(where: { $0.id == snapshotID }) else {
            return
        }
        
        currentCompassLetterInputs = letterInputs
        currentCompassDistanceInputs = distanceInputs
        
        updateSnapshotWithCompassData(snapshot, letterInputs: letterInputs, distanceInputs: distanceInputs)
    }
    
    private func updateSnapshotWithCompassData(_ snapshot: SettingsSnapshot, letterInputs: [String], distanceInputs: [String]) {
        guard let settingsModel = storageManager.decodeSettingsModel(from: snapshot.data) else {
            return
        }
        
        var updatedModel = settingsModel
        updatedModel.compassLetterInputs = letterInputs
        updatedModel.compassDistanceLetterInputs = distanceInputs
        
        guard let encodedData = storageManager.encodeSettingsModel(updatedModel) else { return }
        
        let updatedSnapshot = SettingsSnapshot(
            id: snapshot.id,
            name: snapshot.name,
            date: snapshot.date,
            data: encodedData
        )
        
        storageManager.updateSnapshot(updatedSnapshot)
    }
}