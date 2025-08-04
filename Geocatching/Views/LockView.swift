import SwiftUI

struct LockView: View {
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()

    @FocusState private var focusedIndex: Int?
    @Environment(\.scenePhase) private var scenePhase
    @State private var refreshToggle = false

    private var lockDigits: Int {
        settingsViewModel.lockDigits
    }

    private var enteredLetters: [String] {
        get {
            let letters = Array(settingsViewModel.lockEnteredLetters)
            return (0..<lockDigits).map { i in
                i < letters.count ? String(letters[i]) : ""
            }
        }
        set {
            settingsViewModel.lockEnteredLetters = newValue.joined()
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LockContentView(
                    geometry: geometry,
                    enteredLetters: Binding<[String]>(
                        get: {
                            let letters = Array(settingsViewModel.lockEnteredLetters)
                            return (0..<lockDigits).map { i in
                                i < letters.count ? String(letters[i]) : ""
                            }
                        },
                        set: { newValue in
                            settingsViewModel.lockEnteredLetters = newValue.joined()
                        }
                    ),
                    focusedIndex: $focusedIndex,
                    settingsViewModel: settingsViewModel,
                    alphabetViewModel: alphabetViewModel,
                    clearAllInputs: clearAllInputs,
                    resetInputs: resetInputs,
                    copyCode: copyCode,
                    updateLetter: updateLetter,
                    moveToNext: moveToNext,
                    refreshToggle: $refreshToggle
                )
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            focusedIndex = nil
        }
        .onAppear {
            alphabetViewModel.loadLetterData()
            if settingsViewModel.lockEnteredLetters.count != lockDigits {
                resetInputs()
            }
        }
        .onChange(of: lockDigits) { _ in
            resetInputs()
        }
        .onChange(of: scenePhase) { newPhase in
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: Notification.Name("LockDataChanged"),
                object: nil,
                queue: .main
            ) { notification in
                if let letters = notification.userInfo?["letters"] as? String {
                    settingsViewModel.lockEnteredLetters = letters
                    refreshToggle.toggle()
                }
            }
        }
    }

    private func updateLetter(at index: Int, with letter: String) {
        var letters = enteredLetters
        guard index < lockDigits else { return }
        let filteredLetter = letter.uppercased().filter { $0.isLetter }
        letters[index] = String(filteredLetter.prefix(1))
        settingsViewModel.lockEnteredLetters = letters.joined()
        if !filteredLetter.isEmpty && index < lockDigits - 1 {
            focusedIndex = index + 1
        }
    }

    private func moveToNext(from index: Int) {
        if index < lockDigits - 1 {
            focusedIndex = index + 1
        } else {
            focusedIndex = nil
        }
    }

    private func copyCode() {
        let code = enteredLetters.map { letter in
            if !letter.isEmpty,
               let number = alphabetViewModel.letterNumbers[letter.uppercased()],
               !number.isEmpty {
                return number
            } else {
                return "_"
            }
        }.joined()

        let cleanedCode = code.replacingOccurrences(of: "_", with: "")
        guard !cleanedCode.isEmpty else { return }

        UIPasteboard.general.string = cleanedCode
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func resetInputs() {
        let current = Array(settingsViewModel.lockEnteredLetters)
        let newLetters = (0..<lockDigits).map { i in
            i < current.count ? String(current[i]) : ""
        }
        settingsViewModel.lockEnteredLetters = newLetters.joined()
        focusedIndex = nil
    }

    private func clearAllInputs() {
        let newLetters = Array(repeating: "", count: lockDigits)
        settingsViewModel.lockEnteredLetters = newLetters.joined()
        focusedIndex = nil
    }
}

struct LockContentView: View {
    let geometry: GeometryProxy
    @Binding var enteredLetters: [String]
    var focusedIndex: FocusState<Int?>.Binding
    let settingsViewModel: SettingsViewModel
    let alphabetViewModel: AlphabetViewModel
    let clearAllInputs: () -> Void
    let resetInputs: () -> Void
    let copyCode: () -> Void
    let updateLetter: (Int, String) -> Void
    let moveToNext: (Int) -> Void
    @Binding var refreshToggle: Bool

    var lockDigits: Int {
        settingsViewModel.lockDigits
    }

    var generatedCode: String {
        enteredLetters.map { letter in
            let upper = letter.uppercased()
            if alphabetViewModel.currentAlphabet.contains(upper),
               let number = alphabetViewModel.letterNumbers[upper],
               !number.isEmpty {
                return number
            } else {
                return "_"
            }
        }.joined()
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Lock")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                HStack {
                    Spacer()

                    Button(action: clearAllInputs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                    }
                    .padding(.trailing, 20) 
                }
            }

            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Lock Code Generator")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter letters to generate lock code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                VStack(spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<lockDigits, id: \.self) { index in
                                LetterInputCell(
                                    letter: Binding(
                                        get: { index < enteredLetters.count ? enteredLetters[index] : "" },
                                        set: { newValue in updateLetter(index, newValue) }
                                    ),
                                    index: index,
                                    focusedIndex: focusedIndex,
                                    onSubmit: {
                                        moveToNext(index)
                                    }
                                )
                                .frame(width: 50, height: 60)
                            }
                        }
                        .frame(minWidth: geometry.size.width, maxWidth: .infinity, alignment: .center)
                    }
                    .frame(height: 70)
                    .frame(maxWidth: .infinity) 

                    VStack(spacing: 16) {
                        Text("Generated Code")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        VStack(spacing: 8) {
                            if generatedCode.allSatisfy({ $0 == "_" }) {
                                Text("Enter letters above")
                                    .font(.system(size: 20, weight: .medium, design: .default))
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .multilineTextAlignment(.center)
                            } else {
                                Text(generatedCode)
                                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(minHeight: 60)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.1))
                                .stroke(generatedCode.allSatisfy({ $0 == "_" }) ? Color.secondary.opacity(0.3) : Color.blue.opacity(0.5), lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 20)

                    Button(action: copyCode) {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Copy Code")
                                .fontWeight(.semibold)
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: 220)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .disabled(generatedCode.allSatisfy({ $0 == "_" }))
                    .opacity(generatedCode.allSatisfy({ $0 == "_" }) ? 0.6 : 1.0)
                    .scaleEffect(generatedCode.allSatisfy({ $0 == "_" }) ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: generatedCode)

                    Spacer(minLength: 100)
                }
            }
        }
        .id("lock-\(refreshToggle)")
    }

    struct LetterInputCell: View {
        @Binding var letter: String
        let index: Int
        var focusedIndex: FocusState<Int?>.Binding
        let onSubmit: () -> Void

        var body: some View {
            TextField("", text: $letter)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(width: 50, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                        .stroke((focusedIndex.wrappedValue == index) ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 2)
                )
                .focused(focusedIndex, equals: index)
                .onSubmit {
                    onSubmit()
                }
                .onChange(of: letter) { oldValue, newValue in
                    let filtered = newValue.uppercased().filter { $0.isLetter }
                    if filtered.count > 1 {
                        letter = String(filtered.last!)
                    } else if filtered.count == 1 {
                        letter = filtered
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            onSubmit()
                        }
                    } else if !filtered.isEmpty {
                        letter = filtered
                    } else if newValue.isEmpty {
                        letter = ""
                    }
                }
                .onTapGesture {
                    if focusedIndex.wrappedValue == index {
                        letter = ""
                    } else {
                        focusedIndex.wrappedValue = index
                    }
                }
        }
    }
}
