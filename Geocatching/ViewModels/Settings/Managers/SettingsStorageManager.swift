import Foundation

class SettingsStorageManager {
    private let snapshotsKey = "settings_snapshots"
    
    func getSnapshots() -> [SettingsSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: snapshotsKey),
              let snapshots = try? JSONDecoder().decode([SettingsSnapshot].self, from: data) else {
            return []
        }
        return snapshots.sorted { $0.date > $1.date }
    }
    
    func saveSnapshot(_ snapshot: SettingsSnapshot) {
        var snapshots = getSnapshots()
        snapshots.append(snapshot)
        
        if let encodedSnapshots = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(encodedSnapshots, forKey: snapshotsKey)
        }
    }
    
    func updateSnapshot(_ snapshot: SettingsSnapshot) {
        var snapshots = getSnapshots()
        if let index = snapshots.firstIndex(where: { $0.id == snapshot.id }) {
            snapshots[index] = snapshot
            
            if let encodedSnapshots = try? JSONEncoder().encode(snapshots) {
                UserDefaults.standard.set(encodedSnapshots, forKey: snapshotsKey)
            }
        }
    }
    
    func deleteSnapshot(_ snapshot: SettingsSnapshot) {
        var snapshots = getSnapshots()
        snapshots.removeAll { $0.id == snapshot.id }
        
        if let encodedSnapshots = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(encodedSnapshots, forKey: snapshotsKey)
        }
    }
    
    func deleteSettings(withName name: String) {
        var snapshots = getSnapshots()
        snapshots.removeAll { $0.name == name }
        
        if let encodedSnapshots = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(encodedSnapshots, forKey: snapshotsKey)
        }
        
        UserDefaults.standard.removeObject(forKey: "history_\(name)")
    }
    
    func encodeSettingsModel(_ model: SettingsModel) -> Data? {
        do {
            let dictionary = try model.asDictionary()
            return try JSONSerialization.data(withJSONObject: dictionary, options: [])
        } catch {
            print("Failed to encode settings model: \(error)")
            return nil
        }
    }
    
    func decodeSettingsModel(from data: Data) -> SettingsModel? {
        do {
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return nil
            }
            
            let compassLettersString = dictionary["compassLetterInputs"] as? String ?? ""
            let compassLetters = Array(compassLettersString).map { String($0) }
            let compassLetterInputs = (0..<3).map { i in i < compassLetters.count ? compassLetters[i] : "" }
            
            let compassDistanceString = dictionary["compassDistanceLetterInputs"] as? String ?? ""
            let compassDistance = Array(compassDistanceString).map { String($0) }
            let compassDistanceInputs = (0..<3).map { i in i < compassDistance.count ? compassDistance[i] : "" }
            
            return SettingsModel(
                isDarkMode: dictionary["isDarkMode"] as? Bool ?? false,
                defaultInputFormat: dictionary["defaultInputFormat"] as? String ?? CoordinateFormat.dd.rawValue,
                defaultOutputFormat: dictionary["defaultOutputFormat"] as? String ?? CoordinateFormat.dms.rawValue,
                defaultMapService: dictionary["defaultMapService"] as? String ?? "apple",
                lockDigits: dictionary["lockDigits"] as? Int ?? 4,
                lockEnteredLetters: dictionary["lockEnteredLetters"] as? String ?? "",
                letterNumbers: dictionary["letterNumbers"] as? [String: String] ?? [:],
                selectedAlphabet: dictionary["selectedAlphabet"] as? String ?? "english",
                letterImages: dictionary["letterImages"] as? [String: String] ?? [:],
                compassLetterInputs: compassLetterInputs,
                compassDistanceLetterInputs: compassDistanceInputs,
                generalNote: dictionary["generalNote"] as? String ?? "",
                latitude: dictionary["latitude"] as? String,
                longitude: dictionary["longitude"] as? String,
                fromFormat: dictionary["fromFormat"] as? String,
                toFormat: dictionary["toFormat"] as? String
            )
        } catch {
            print("Failed to decode settings data: \(error)")
            return nil
        }
    }
}