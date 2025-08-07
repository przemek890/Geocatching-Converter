import Foundation
import SwiftUI
import Combine

class AlphabetViewModel: ObservableObject {
    @AppStorage("selectedAlphabet") var selectedAlphabet = "english"
    @Published var letterNumbers: [String: String] = [:]
    @Published var letterImages: [String: Data] = [:]
    private var isLoadingFromSnapshot = false
    private var currentSnapshotID: String = ""
    
    var currentAlphabet: [String] {
        Alphabets.getCurrent(for: selectedAlphabet)
    }
    
    private func imageFileURL(for letter: String, snapshotID: String) -> URL {
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let snapshotDir = dir.appendingPathComponent("snapshots/\(snapshotID)", isDirectory: true)
        if !fileManager.fileExists(atPath: snapshotDir.path) {
            try? fileManager.createDirectory(at: snapshotDir, withIntermediateDirectories: true)
        }
        let safeLetter = safeFileName(letter)
        let safeAlphabet = safeFileName(selectedAlphabet)
        return snapshotDir.appendingPathComponent("img_\(safeAlphabet)_\(safeLetter)")
    }
    
    private func safeFileName(_ string: String) -> String {
        let unsafeChars = CharacterSet.alphanumerics.inverted
        return string.components(separatedBy: unsafeChars).joined(separator: "_")
    }
    
    func loadLetterData(forSnapshotID snapshotID: String) {
        if isLoadingFromSnapshot { return }
        isLoadingFromSnapshot = true
        currentSnapshotID = snapshotID

        DispatchQueue.global(qos: .userInitiated).async {
            var loadedNumbers: [String: String] = [:]
            var loadedImages: [String: Data] = [:]
            let key = "letterData_\(self.selectedAlphabet)_\(snapshotID)"
            if let numbersData = UserDefaults.standard.data(forKey: "\(key)_numbers"),
               let numbers = try? JSONDecoder().decode([String: String].self, from: numbersData) {
                loadedNumbers = numbers
            }
            if let pathsData = UserDefaults.standard.data(forKey: "\(key)_images"),
               let imagePaths = try? JSONDecoder().decode([String: String].self, from: pathsData) {
                for (letter, _) in imagePaths {
                    let url = self.imageFileURL(for: letter, snapshotID: snapshotID)
                    if let data = try? Data(contentsOf: url) {
                        loadedImages[letter] = data
                    }
                }
            }
            DispatchQueue.main.async {
                self.letterNumbers = loadedNumbers
                self.letterImages = loadedImages
                self.isLoadingFromSnapshot = false
            }
        }
    }
    
    func saveLetterData(forSnapshotID snapshotID: String) {
        if isLoadingFromSnapshot { return }
        let key = "letterData_\(selectedAlphabet)_\(snapshotID)"
        if let numbersData = try? JSONEncoder().encode(letterNumbers) {
            UserDefaults.standard.set(numbersData, forKey: "\(key)_numbers")
        }
        var imagePaths: [String: String] = [:]
        for (letter, data) in letterImages {
            let url = imageFileURL(for: letter, snapshotID: snapshotID)
            do {
                try data.write(to: url)
                imagePaths[letter] = url.lastPathComponent
            } catch {
                print("Failed to write image for letter \(letter): \(error)")
            }
        }
        if let pathsData = try? JSONEncoder().encode(imagePaths) {
            UserDefaults.standard.set(pathsData, forKey: "\(key)_images")
        }
    }
    
    func setAlphabetType(type: String, snapshotID: String) {
        let oldType = selectedAlphabet
        selectedAlphabet = type
        if oldType != type {
            loadLetterData(forSnapshotID: snapshotID)
        }
    }
    
    func resetAllLetters(forSnapshotID snapshotID: String) {
        let key = "letterData_\(selectedAlphabet)_\(snapshotID)"
        letterNumbers.removeAll()
        letterImages.removeAll()
        UserDefaults.standard.removeObject(forKey: "\(key)_numbers")
        UserDefaults.standard.removeObject(forKey: "\(key)_images")
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let snapshotDir = dir.appendingPathComponent("snapshots/\(snapshotID)", isDirectory: true)
        try? fileManager.removeItem(at: snapshotDir)
    }
}
