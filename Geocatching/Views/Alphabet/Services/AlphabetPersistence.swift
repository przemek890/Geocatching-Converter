import Foundation

class AlphabetPersistenceService {
    static func saveLetterData(letterNumbers: [String: String], letterImages: [String: Data], for alphabet: String, snapshotID: String? = nil) {
        let snapshotSuffix = snapshotID != nil ? "_\(snapshotID!)" : ""
        let key = "letterData_\(alphabet)\(snapshotSuffix)"
        
        if let numbersData = try? JSONEncoder().encode(letterNumbers) {
            UserDefaults.standard.set(numbersData, forKey: "\(key)_numbers")
        }
        if let imagesData = try? JSONEncoder().encode(letterImages) {
            UserDefaults.standard.set(imagesData, forKey: "\(key)_images")
        }
    }
    
    static func loadLetterData(for alphabet: String, snapshotID: String? = nil) -> ([String: String], [String: Data]) {
        let snapshotSuffix = snapshotID != nil ? "_\(snapshotID!)" : ""
        let key = "letterData_\(alphabet)\(snapshotSuffix)"
        
        let numbers = (UserDefaults.standard.data(forKey: "\(key)_numbers").flatMap { 
            try? JSONDecoder().decode([String: String].self, from: $0) 
        }) ?? [:]
        
        let images = (UserDefaults.standard.data(forKey: "\(key)_images").flatMap { 
            try? JSONDecoder().decode([String: Data].self, from: $0) 
        }) ?? [:]
        
        return (numbers, images)
    }
}