import Foundation

protocol AlphabetViewModelProtocol: ObservableObject {
    var letterNumbers: [String: String] { get set }
    var letterImages: [String: Data] { get set }
    var selectedAlphabet: String { get set }
    
    func loadLetterData(forSnapshotID snapshotID: String)
    func saveLetterData(forSnapshotID snapshotID: String)
    func resetAllLetters(forSnapshotID snapshotID: String)
}