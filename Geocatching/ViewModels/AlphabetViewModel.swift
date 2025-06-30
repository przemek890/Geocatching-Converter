import Foundation
import SwiftUI
import Combine

class AlphabetViewModel: ObservableObject {
    @AppStorage("selectedAlphabet") var selectedAlphabet = "english"
    @Published var letterNumbers: [String: String] = [:]
    @Published var letterImages: [String: Data] = [:]
    
    var currentAlphabet: [String] {
        Alphabets.getCurrent(for: selectedAlphabet)
    }
    
    init() {
        loadLetterData()
    }
    
    func loadLetterData() {
        let key = "letterData_\(selectedAlphabet)"
        if let numbersData = UserDefaults.standard.data(forKey: "\(key)_numbers"),
           let numbers = try? JSONDecoder().decode([String: String].self, from: numbersData) {
            letterNumbers = numbers
        } else {
            letterNumbers = [:]
        }

        if let imagesData = UserDefaults.standard.data(forKey: "\(key)_images"),
           let images = try? JSONDecoder().decode([String: Data].self, from: imagesData) {
            letterImages = images
        } else {
            letterImages = [:]
        }
    }
    
    func setAlphabetType(type: String) {
        selectedAlphabet = type
        loadLetterData()
    }
    
    func saveLetterData() {
        let key = "letterData_\(selectedAlphabet)"
        if let numbersData = try? JSONEncoder().encode(letterNumbers) {
            UserDefaults.standard.set(numbersData, forKey: "\(key)_numbers")
        }
        if let imagesData = try? JSONEncoder().encode(letterImages) {
            UserDefaults.standard.set(imagesData, forKey: "\(key)_images")
        }
    }
    
    func resetAllLetters() {
        let key = "letterData_\(selectedAlphabet)"
        letterNumbers.removeAll()
        letterImages.removeAll()
        UserDefaults.standard.removeObject(forKey: "\(key)_numbers")
        UserDefaults.standard.removeObject(forKey: "\(key)_images")
    }
}
