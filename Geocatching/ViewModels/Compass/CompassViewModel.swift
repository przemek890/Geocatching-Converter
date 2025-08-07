import SwiftUI
import Combine
import Foundation

class CompassViewModel: ObservableObject {
    @Published var letterInputs: [String] = ["", "", ""]
    @Published var distanceInputs: [String] = ["", "", ""]
    @Published var focusedIndex: Int? = nil
    @Published var showingClearConfirmation = false
    @Published var compassData = CompassData(
        azimuth: nil, distance: nil, deviceHeading: 0,
        azimuthText: "___", distanceText: "___"
    )
    
    let alphabetViewModel: AlphabetViewModel
    let locationService: LocationService
    private let settingsViewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private var isLoadingSnapshot = false
    private var lastLoadedLetterInputs: [String] = ["", "", ""]
    private var lastLoadedDistanceInputs: [String] = ["", "", ""]
    
    init(
        alphabetViewModel: AlphabetViewModel,
        locationService: LocationService,
        settingsViewModel: SettingsViewModel
    ) {
        self.alphabetViewModel = alphabetViewModel
        self.locationService = locationService
        self.settingsViewModel = settingsViewModel
        
        setupBindings()
        setupNotifications()
        loadInitialData()
    }
    
    private func setupBindings() {
        locationService.$heading
            .sink { [weak self] heading in
                self?.compassData.deviceHeading = heading
            }
            .store(in: &cancellables)
        
        $letterInputs
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] inputs in
                guard let self = self else { return }
                if self.isLoadingSnapshot { return }
                if inputs == self.lastLoadedLetterInputs { return }
                self.saveDataToSnapshot()
                self.updateCompassData()
            }
            .store(in: &cancellables)
        
        $distanceInputs
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] inputs in
                guard let self = self else { return }
                if self.isLoadingSnapshot { return }
                if inputs == self.lastLoadedDistanceInputs { return }
                self.saveDataToSnapshot()
                self.updateCompassData()
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: Notification.Name("CurrentSnapshotChanged"))
            .compactMap { $0.userInfo?["snapshotID"] as? String }
            .sink { [weak self] snapshotID in
                self?.loadDataForSnapshot(snapshotID: snapshotID)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("CompassDataReset"))
            .compactMap { $0.userInfo?["snapshotID"] as? String }
            .sink { [weak self] snapshotID in
                self?.resetInputs()
                self?.saveDataToSnapshot(snapshotID: snapshotID)
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        if let currentID = settingsViewModel.currentSnapshotID {
            loadDataForSnapshot(snapshotID: currentID)
        } else {
            resetInputs()
        }
    }
    
    private func loadDataForSnapshot(snapshotID: String) {
        isLoadingSnapshot = true
        alphabetViewModel.loadLetterData(forSnapshotID: snapshotID)
        
        let letterKey = "compassLetterInputs_\(snapshotID)"
        if let savedData = UserDefaults.standard.data(forKey: letterKey),
           let savedLetters = try? JSONDecoder().decode([String].self, from: savedData) {
            letterInputs = savedLetters
        } else {
            letterInputs = ["", "", ""]
        }
        
        let distanceKey = "compassDistanceInputs_\(snapshotID)"
        if let savedData = UserDefaults.standard.data(forKey: distanceKey),
           let savedDistance = try? JSONDecoder().decode([String].self, from: savedData) {
            distanceInputs = savedDistance
        } else {
            distanceInputs = ["", "", ""]
        }
        
        lastLoadedLetterInputs = letterInputs
        lastLoadedDistanceInputs = distanceInputs
        focusedIndex = 0
        updateCompassData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isLoadingSnapshot = false
        }
    }
    
    private func saveDataToSnapshot() {
        guard let snapshotID = settingsViewModel.currentSnapshotID else { return }
        saveDataToSnapshot(snapshotID: snapshotID)
    }
    
    private func saveDataToSnapshot(snapshotID: String) {
        let letterKey = "compassLetterInputs_\(snapshotID)"
        if let encoded = try? JSONEncoder().encode(letterInputs) {
            UserDefaults.standard.set(encoded, forKey: letterKey)
        }
        
        let distanceKey = "compassDistanceInputs_\(snapshotID)"
        if let encoded = try? JSONEncoder().encode(distanceInputs) {
            UserDefaults.standard.set(encoded, forKey: distanceKey)
        }
        
        lastLoadedLetterInputs = letterInputs
        lastLoadedDistanceInputs = distanceInputs
    }
    
    func updateLetterInput(at index: Int, with value: String) {
        guard index < letterInputs.count else { return }
        let filtered = value.uppercased().filter { $0.isLetter }
        letterInputs[index] = String(filtered.prefix(1))
        if !filtered.isEmpty && index < letterInputs.count - 1 {
            focusedIndex = index + 1
        }
    }
    
    func updateDistanceInput(at index: Int, with value: String) {
        guard index < distanceInputs.count else { return }
        let filtered = value.uppercased().filter { $0.isLetter }
        distanceInputs[index] = String(filtered.prefix(1))
        if !filtered.isEmpty {
            let nextIndex = index - 1
            if nextIndex >= 0 {
                focusedIndex = nextIndex + 3
            }
        }
    }
    
    func clearInputs() {
        letterInputs = ["", "", ""]
        distanceInputs = ["", "", ""]
        focusedIndex = nil
        updateCompassData()
        if let snapshotID = settingsViewModel.currentSnapshotID {
            saveDataToSnapshot(snapshotID: snapshotID)
        }
    }
    
    private func resetInputs() {
        letterInputs = ["", "", ""]
        distanceInputs = ["", "", ""]
        focusedIndex = nil
        updateCompassData()
    }
    
    private func updateCompassData() {
        let azimuth = calculateAzimuth()
        let distance = calculateDistance()
        
        compassData = CompassData(
            azimuth: azimuth,
            distance: distance,
            deviceHeading: locationService.heading,
            azimuthText: azimuth != nil ? "\(azimuth!)°" : "___",
            distanceText: distance != nil ? "\(distance!)" : "___"
        )
    }
    
    func recalculateCompassData() {
        updateCompassData()
    }
    
    private func calculateAzimuth() -> Int? {
        let validLetters = letterInputs.filter { !$0.isEmpty }
        guard validLetters.count == 3 else { return nil }
        var value = 0
        for (idx, letter) in letterInputs.enumerated() {
            guard let numStr = alphabetViewModel.letterNumbers[letter.uppercased()],
                  let num = Int(numStr) else { return nil }
            value += num * Int(pow(10.0, Double(2 - idx)))
        }
        return value % 360
    }
    
    private func calculateDistance() -> Int? {
        let validLetters = distanceInputs.filter { !$0.isEmpty }
        guard validLetters.count == 3 else { return nil }
        var value = 0
        for (idx, letter) in distanceInputs.enumerated() {
            guard let numStr = alphabetViewModel.letterNumbers[letter.uppercased()],
                  let num = Int(numStr) else { return nil }
            value += num * Int(pow(10.0, Double(idx)))
        }
        return value
    }
    
    func startCompassIfActive() {
        if locationService.isActive {
            locationService.startUpdatingHeading()
        }
    }
    
    func stopCompass() {
        locationService.stopUpdatingHeading()
    }
    
    func toggleCompass() {
        if locationService.isActive {
            locationService.stopUpdatingHeading()
        } else {
            locationService.startUpdatingHeading()
        }
        objectWillChange.send()
    }
    
    func dismissFocus() {
        focusedIndex = nil
    }
    
    func showClearConfirmation() {
        showingClearConfirmation = true
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}