import Foundation

struct SettingsModel: Codable {
    var isDarkMode: Bool
    var defaultInputFormat: String
    var defaultOutputFormat: String
    var defaultMapService: String
    var lockDigits: Int
    var lockEnteredLetters: String
    
    var letterNumbers: [String: String]
    var selectedAlphabet: String
    var letterImages: [String: String]
    
    var compassLetterInputs: [String]
    var compassDistanceLetterInputs: [String]
    var generalNote: String
    
    var latitude: String?
    var longitude: String?
    var fromFormat: String?
    var toFormat: String?
    
    static var `default`: SettingsModel {
        SettingsModel(
            isDarkMode: true,
            defaultInputFormat: CoordinateFormat.ddm.rawValue,
            defaultOutputFormat: CoordinateFormat.dd.rawValue,
            defaultMapService: "google",
            lockDigits: 5,
            lockEnteredLetters: "",
            letterNumbers: [:],
            selectedAlphabet: "english",
            letterImages: [:],
            compassLetterInputs: ["", "", ""],
            compassDistanceLetterInputs: ["", "", ""],
            generalNote: "",
            latitude: nil,
            longitude: nil,
            fromFormat: nil,
            toFormat: nil
        )
    }
}