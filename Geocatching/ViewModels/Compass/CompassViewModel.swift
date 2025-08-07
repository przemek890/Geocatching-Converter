import SwiftUI
import Foundation
import CoreLocation
import Combine

class CompassViewModel: ObservableObject {
    @Published var letterInputs: [String] = ["", "", ""]
    @Published var distanceInputs: [String] = ["", "", ""]
    @Published var focusedIndex: Int? = nil
    @Published var showingClearConfirmation = false
    @Published var compassData: CompassData = CompassData(
        azimuth: nil,
        distance: nil,
        deviceHeading: 0.0,
        azimuthText: "___",
        distanceText: "___"
    )
    
    let locationService: LocationService
    private let alphabetViewModel: AlphabetViewModel
    
    @AppStorage("currentSnapshotID") private var currentSnapshotID: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var snapshotObserver: AnyCancellable?
    private var isLoadingSnapshot = false
    
    private var lastLoadedLetterInputs: [String] = ["", "", ""]
    private var lastLoadedDistanceInputs: [String] = ["", "", ""]
    
    init(alphabetViewModel: AlphabetViewModel, locationService: LocationService) {
        self.alphabetViewModel = alphabetViewModel
        self.locationService = locationService
        
        setupBindings()
        loadInitialData()
        
        snapshotObserver = NotificationCenter.default.publisher(for: Notification.Name("CurrentSnapshotChanged"))
            .sink { [weak self] notification in
                if let userInfo = notification.userInfo,
                   let newID = userInfo["snapshotID"] as? String,
                   let letterInputs = userInfo["compassLetterInputs"] as? [String],
                   let distanceInputs = userInfo["compassDistanceInputs"] as? [String] {
                    self?.reloadDataForSnapshot(id: newID, letterInputs: letterInputs, distanceInputs: distanceInputs)
                }
            }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCompassDataReset),
            name: Notification.Name("CompassDataReset"),
            object: nil
        )
    }
    
    private func setupBindings() {
        locationService.$heading
            .sink { [weak self] _ in
                self?.updateCompassData()
            }
            .store(in: &cancellables)
        
        $letterInputs
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] inputs in
                guard let self = self else { return }
                if self.isLoadingSnapshot { return }
                if inputs == self.lastLoadedLetterInputs { return }
                self.saveCurrentDataToSnapshot()
                self.updateCompassData()
            }
            .store(in: &cancellables)
        
        $distanceInputs
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] inputs in
                guard let self = self else { return }
                if self.isLoadingSnapshot { return }
                if inputs == self.lastLoadedDistanceInputs { return }
                self.saveCurrentDataToSnapshot()
                self.updateCompassData()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        alphabetViewModel.loadLetterData(forSnapshotID: currentSnapshotID ?? "")
        if let _ = currentSnapshotID {}
        focusedIndex = 0
        updateCompassData()
    }
    
    func toggleCompass() {
        if locationService.isActive {
            locationService.stopUpdatingHeading()
        } else {
            locationService.startUpdatingHeading()
        }
        objectWillChange.send()
    }
    
    func updateLetterInput(at index: Int, with value: String) {
        let filtered = value.uppercased().filter { $0.isLetter }
        let singleChar = String(filtered.prefix(1))
        
        if !letterInputs[index].isEmpty && !singleChar.isEmpty {
            letterInputs[index] = singleChar
            moveToNextField(from: index, isDistance: false)
        } else if singleChar.isEmpty {
            letterInputs[index] = ""
        } else {
            letterInputs[index] = singleChar
            moveToNextField(from: index, isDistance: false)
        }
        
        if letterInputs != lastLoadedLetterInputs {
            lastLoadedLetterInputs = letterInputs
        }
    }
    
    func updateDistanceInput(at index: Int, with value: String) {
        let filtered = value.uppercased().filter { $0.isLetter }
        let singleChar = String(filtered.prefix(1))
        
        if !distanceInputs[index].isEmpty && !singleChar.isEmpty {
            distanceInputs[index] = singleChar
            moveToNextField(from: index, isDistance: true)
        } else if singleChar.isEmpty {
            distanceInputs[index] = ""
        } else {
            distanceInputs[index] = singleChar
            moveToNextField(from: index, isDistance: true)
        }
        
        if distanceInputs != lastLoadedDistanceInputs {
            lastLoadedDistanceInputs = distanceInputs
        }
    }
    
    func clearInputs() {
        letterInputs = ["", "", ""]
        distanceInputs = ["", "", ""]
        focusedIndex = 0
        lastLoadedLetterInputs = letterInputs
        lastLoadedDistanceInputs = distanceInputs
        saveCurrentDataToSnapshot()
        updateCompassData()
    }
    
    func dismissFocus() {
        focusedIndex = nil
    }
    
    func showClearConfirmation() {
        showingClearConfirmation = true
    }
    
    func startCompassIfActive() {
        if locationService.isActive {
            locationService.startUpdatingHeading()
        }
    }
    
    func stopCompass() {
        locationService.stopUpdatingHeading()
    }
    
    private func moveToNextField(from currentIndex: Int, isDistance: Bool) {
        if isDistance {
            if currentIndex > 0 {
                focusedIndex = currentIndex + 3 - 1
            } else {
                focusedIndex = nil
            }
        } else {
            if currentIndex < 2 {
                focusedIndex = currentIndex + 1
            } else {
                focusedIndex = 3 + 2
            }
        }
    }
    
    private func updateCompassData() {
        let azimuthCode = calculateAzimuthCode()
        let azimuth = calculateAzimuth(from: azimuthCode)
        let distanceCode = calculateDistanceCode()
        let distance = calculateDistance(from: distanceCode)
        
        compassData = CompassData(
            azimuth: azimuth,
            distance: distance,
            deviceHeading: locationService.heading,
            azimuthText: azimuthCode == "___" ? "___" : azimuthCode,
            distanceText: distanceCode == "___" ? "___" : distanceCode
        )
    }
    
    private func calculateAzimuthCode() -> String {
        var code = ""
        for letter in letterInputs {
            if letter.isEmpty {
                code += "_"
            } else {
                let upperLetter = letter.uppercased()
                if let numberValue = alphabetViewModel.letterNumbers[upperLetter] {
                    code += numberValue
                } else {
                    code += "_"
                }
            }
        }
        return code
    }
    
    private func calculateAzimuth(from code: String) -> Int? {
        if code == "___" { return nil }
        if code == "__" + String(code.last!), let d = Int(String(code.last!)) {
            return d % 360
        }
        if code.first == "_", code[code.index(code.startIndex, offsetBy: 1)] != "_", code.last! != "_",
           let d1 = Int(String(code[code.index(code.startIndex, offsetBy: 1)])),
           let d2 = Int(String(code.last!)) {
            return (d1 * 10 + d2) % 360
        }
        if !code.contains("_"),
           let d0 = Int(String(code.first!)),
           let d1 = Int(String(code[code.index(code.startIndex, offsetBy: 1)])),
           let d2 = Int(String(code.last!)) {
            return (d0 * 100 + d1 * 10 + d2) % 360
        }
        return nil
    }
    
    private func calculateDistanceCode() -> String {
        return distanceInputs
            .reversed()
            .map { letter in
                if letter.isEmpty {
                    return "_"
                } else {
                    let upperLetter = letter.uppercased()
                    if let numberValue = alphabetViewModel.letterNumbers[upperLetter] {
                        return numberValue
                    }
                    return "_"
                }
            }
            .joined()
    }
    
    private func calculateDistance(from code: String) -> Int? {
        if code.contains("_") { return nil }
        return Int(code)
    }
    
    func recalculateCompassData() {
        updateCompassData()
        objectWillChange.send()
    }
    
    func reloadDataForSnapshot(id: String?, letterInputs: [String], distanceInputs: [String]) {
        isLoadingSnapshot = true
        lastLoadedLetterInputs = letterInputs
        lastLoadedDistanceInputs = distanceInputs
        DispatchQueue.main.async {
            self.letterInputs = letterInputs
            self.distanceInputs = distanceInputs
            self.objectWillChange.send()
            self.updateCompassData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isLoadingSnapshot = false
            }
        }
    }
    
    @objc private func handleCompassDataReset(_ notification: Notification) {
        isLoadingSnapshot = true
        DispatchQueue.main.async {
            self.letterInputs = ["", "", ""]
            self.distanceInputs = ["", "", ""]
            self.lastLoadedLetterInputs = ["", "", ""]
            self.lastLoadedDistanceInputs = ["", "", ""]
            self.updateCompassData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isLoadingSnapshot = false
            }
        }
    }
    
    private func saveCurrentDataToSnapshot() {
        guard let snapshotID = currentSnapshotID, !isLoadingSnapshot else { return }
        NotificationCenter.default.post(
            name: Notification.Name("CompassDataChanged"),
            object: nil,
            userInfo: [
                "letterInputs": letterInputs,
                "distanceInputs": distanceInputs,
                "snapshotID": snapshotID
            ]
        )
    }
}
