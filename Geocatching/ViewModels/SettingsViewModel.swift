import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("defaultInputFormat") var defaultInputFormat = CoordinateFormat.dd.rawValue
    @AppStorage("defaultOutputFormat") var defaultOutputFormat = CoordinateFormat.dms.rawValue
    @AppStorage("defaultMapService") var defaultMapService = "apple"
    @AppStorage("lockDigits") var lockDigits = 4
    @AppStorage("lockEnteredLetters") var lockEnteredLetters: String = ""
    
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
    }
}

extension SettingsViewModel {
    func getSavedSettingsNames() -> [String] {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        return keys.filter { $0.starts(with: "history_") }.map { $0.replacingOccurrences(of: "history_", with: "") }
    }
    
    func saveCurrentSettings(as name: String, alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
        Task { @MainActor in
            var settings: [String: Any] = [:]
            
            settings["isDarkMode"] = isDarkMode
            settings["defaultInputFormat"] = defaultInputFormat
            settings["defaultOutputFormat"] = defaultOutputFormat
            settings["defaultMapService"] = defaultMapService
            settings["lockDigits"] = lockDigits
            settings["lockEnteredLetters"] = lockEnteredLetters
            
            settings["letterNumbers"] = alphabetViewModel.letterNumbers
            settings["selectedAlphabet"] = alphabetViewModel.selectedAlphabet
            
            let encodedLetterImages = alphabetViewModel.letterImages.mapValues { $0.base64EncodedString() }
            settings["letterImages"] = encodedLetterImages
            
            settings["latitude"] = coordinateViewModel.latitude.toString()
            settings["longitude"] = coordinateViewModel.longitude.toString()
            
            settings["compassLetterInputs"] = UserDefaults.standard.string(forKey: "compassLetterInputs") ?? ""
            settings["compassDistanceLetterInputs"] = UserDefaults.standard.string(forKey: "compassDistanceLetterInputs") ?? ""
            
            settings["generalNote"] = UserDefaults.standard.string(forKey: "generalNote") ?? ""
            
            guard let data = try? JSONSerialization.data(withJSONObject: settings, options: []) else { return }
            
            let snapshot = SettingsSnapshot(
                id: UUID().uuidString,
                name: name,
                date: Date(),
                data: data
            )
            
            var snapshots = getSnapshots()
            snapshots.append(snapshot)
            
            if let encodedSnapshots = try? JSONEncoder().encode(snapshots) {
                UserDefaults.standard.set(encodedSnapshots, forKey: "settings_snapshots")
            }
        }
    }
    
    @MainActor
    func loadSettings(from name: String, alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
        let key = "history_\(name)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return
        }
        
        isDarkMode = settings["isDarkMode"] as? Bool ?? false
        defaultInputFormat = settings["defaultInputFormat"] as? String ?? CoordinateFormat.dd.rawValue
        defaultOutputFormat = settings["defaultOutputFormat"] as? String ?? CoordinateFormat.dms.rawValue
        defaultMapService = settings["defaultMapService"] as? String ?? "apple"
        lockDigits = settings["lockDigits"] as? Int ?? 4
        lockEnteredLetters = settings["lockEnteredLetters"] as? String ?? ""
        
        alphabetViewModel.letterNumbers = settings["letterNumbers"] as? [String: String] ?? [:]
        alphabetViewModel.letterImages = settings["letterImages"] as? [String: Data] ?? [:]
        
        if let latitudeString = settings["latitude"] as? String {
            coordinateViewModel.latitude = Coordinate.fromString(latitudeString, direction: .north) ?? Coordinate(direction: .north)
        }
        if let longitudeString = settings["longitude"] as? String {
            coordinateViewModel.longitude = Coordinate.fromString(longitudeString, direction: .east) ?? Coordinate(direction: .east)
        }
    }
}

extension SettingsViewModel {
    func getSnapshots() -> [SettingsSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: "settings_snapshots"),
              let snapshots = try? JSONDecoder().decode([SettingsSnapshot].self, from: data) else {
            return []
        }
        return snapshots.sorted { $0.date > $1.date }
    }
    
    @MainActor
    func loadSnapshot(_ snapshot: SettingsSnapshot, alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) {
        guard let settings = try? JSONSerialization.jsonObject(with: snapshot.data, options: []) as? [String: Any] else {
            return
        }
        
        isDarkMode = settings["isDarkMode"] as? Bool ?? false
        defaultInputFormat = settings["defaultInputFormat"] as? String ?? CoordinateFormat.dd.rawValue
        defaultOutputFormat = settings["defaultOutputFormat"] as? String ?? CoordinateFormat.dms.rawValue
        defaultMapService = settings["defaultMapService"] as? String ?? "apple"
        lockDigits = settings["lockDigits"] as? Int ?? 4
        lockEnteredLetters = settings["lockEnteredLetters"] as? String ?? ""
        
        alphabetViewModel.letterNumbers = settings["letterNumbers"] as? [String: String] ?? [:]
        alphabetViewModel.selectedAlphabet = settings["selectedAlphabet"] as? String ?? "english"
        
        if let encodedLetterImages = settings["letterImages"] as? [String: String] {
            alphabetViewModel.letterImages = encodedLetterImages.compactMapValues { Data(base64Encoded: $0) }
        }
        
        if let latitudeString = settings["latitude"] as? String {
            coordinateViewModel.latitude = Coordinate.fromString(latitudeString, direction: .north) ?? Coordinate(direction: .north)
        }
        if let longitudeString = settings["longitude"] as? String {
            coordinateViewModel.longitude = Coordinate.fromString(longitudeString, direction: .east) ?? Coordinate(direction: .east)
        }
        
        UserDefaults.standard.set(settings["compassLetterInputs"] as? String ?? "", forKey: "compassLetterInputs")
        UserDefaults.standard.set(settings["compassDistanceLetterInputs"] as? String ?? "", forKey: "compassDistanceLetterInputs")
        
        UserDefaults.standard.set(settings["generalNote"] as? String ?? "", forKey: "generalNote")
    }
}

extension SettingsViewModel {
    func createSnapshotData(alphabetViewModel: AlphabetViewModel, coordinateViewModel: CoordinateViewModel) -> Data {
        var settings: [String: Any] = [:]
        
        settings["isDarkMode"] = isDarkMode
        settings["defaultInputFormat"] = defaultInputFormat
        settings["defaultOutputFormat"] = defaultOutputFormat
        settings["defaultMapService"] = defaultMapService
        settings["lockDigits"] = lockDigits
        settings["lockEnteredLetters"] = lockEnteredLetters
        
        settings["letterNumbers"] = alphabetViewModel.letterNumbers
        
        let encodedLetterImages = alphabetViewModel.letterImages.mapValues { $0.base64EncodedString() }
        settings["letterImages"] = encodedLetterImages
        
        Task { @MainActor in
            settings["latitude"] = coordinateViewModel.latitude.toString()
            settings["longitude"] = coordinateViewModel.longitude.toString()
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: settings, options: []) else {
            fatalError("Failed to encode snapshot data")
        }
        
        return data
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
        alphabetViewModel.saveLetterData()

        coordinateViewModel.latitude = Coordinate(direction: .north)
        coordinateViewModel.longitude = Coordinate(direction: .east)
        coordinateViewModel.convertedLatitude = Coordinate(direction: .north)
        coordinateViewModel.convertedLongitude = Coordinate(direction: .east)
        coordinateViewModel.fromFormat = .ddm
        coordinateViewModel.toFormat = .dd

        UserDefaults.standard.set("", forKey: "compassLetterInputs")
        UserDefaults.standard.set("", forKey: "compassDistanceLetterInputs")

        UserDefaults.standard.set("", forKey: "generalNote")
    }
}
