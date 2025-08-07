import SwiftUI


class LockViewModel: ObservableObject {
    @Published var lockModel = LockModel()
    @Published var focusedIndex: Int?
    @Published var refreshToggle = false
    @Published var showingClearConfirmation = false
    
    let settingsViewModel: SettingsViewModel
    private let alphabetViewModel: AlphabetViewModel
    
    init(settingsViewModel: SettingsViewModel, alphabetViewModel: AlphabetViewModel) {
        self.settingsViewModel = settingsViewModel
        self.alphabetViewModel = alphabetViewModel
        
        self.lockModel.enteredLetters = settingsViewModel.lockEnteredLetters
        setupNotifications()
    }
    
    var enteredLetters: [String] {
        get {
            lockModel.getLettersArray(lockDigits: settingsViewModel.lockDigits)
        }
        set {
            lockModel.enteredLetters = newValue.joined()
            settingsViewModel.lockEnteredLetters = lockModel.enteredLetters
        }
    }
    
    var generatedCode: String {
        lockModel.generateCode(using: alphabetViewModel)
    }
    
    var lockDigits: Int {
        return settingsViewModel.lockDigits
    }
    
    func updateLetter(at index: Int, with letter: String) {
        var letters = enteredLetters
        guard index < lockDigits else { return }
        
        let filteredLetter = letter.uppercased().filter { $0.isLetter }
        letters[index] = String(filteredLetter.prefix(1))
        enteredLetters = letters
        
        if !filteredLetter.isEmpty && index < lockDigits - 1 {
            focusedIndex = index + 1
        }
    }
    
    func moveToNext(from index: Int) {
        if index < lockDigits - 1 {
            focusedIndex = index + 1
        } else {
            focusedIndex = nil
        }
    }
    
    func copyCode() {
        let cleanedCode = generatedCode.replacingOccurrences(of: "_", with: "")
        guard !cleanedCode.isEmpty else { return }
        
        UIPasteboard.general.string = cleanedCode
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func resetInputs() {
        let current = Array(settingsViewModel.lockEnteredLetters)
        let newLetters = (0..<lockDigits).map { i in
            i < current.count ? String(current[i]) : ""
        }
        lockModel.enteredLetters = newLetters.joined()
        settingsViewModel.lockEnteredLetters = lockModel.enteredLetters
        focusedIndex = nil
    }
    
    func clearAllInputs() {
        lockModel.enteredLetters = String(repeating: "", count: lockDigits)
        settingsViewModel.lockEnteredLetters = lockModel.enteredLetters
        focusedIndex = nil
    }
    
    func updateLockDigits(_ newDigits: Int) {
        resetInputs()
    }
    
    func loadInitialData() {
        if settingsViewModel.lockEnteredLetters.count != lockDigits {
            resetInputs()
        }
        refreshToggle.toggle()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("LockDataChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let letters = notification.userInfo?["letters"] as? String {
                self?.lockModel.enteredLetters = letters
                self?.settingsViewModel.lockEnteredLetters = letters
                self?.refreshToggle.toggle()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("LockDigitsChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.lockModel.lockDigits != self.settingsViewModel.lockDigits {
                self.updateLockDigits(self.settingsViewModel.lockDigits)
                self.refreshToggle.toggle()
            }
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name("CurrentSnapshotChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resetInputs()
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("LockDataChanged"), object: nil)
    }
}
