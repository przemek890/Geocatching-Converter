import Foundation

struct SettingsSnapshot: Codable, Identifiable {
    let id: String
    let name: String
    let date: Date
    let data: Data
}