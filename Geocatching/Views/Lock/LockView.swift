import SwiftUI

struct LockView: View {
    @StateObject private var viewModel: LockViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    init(alphabetViewModel: AlphabetViewModel, settingsViewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: LockViewModel(
            settingsViewModel: settingsViewModel,
            alphabetViewModel: alphabetViewModel
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LockContentView(
                    geometry: geometry,
                    viewModel: viewModel
                )
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            viewModel.focusedIndex = nil
        }
        .onAppear {
            viewModel.loadInitialData()
        }
        .onChange(of: viewModel.lockDigits) {
            viewModel.resetInputs()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                if viewModel.lockDigits != viewModel.settingsViewModel.lockDigits {
                    viewModel.updateLockDigits(viewModel.settingsViewModel.lockDigits)
                }
            }
        }
    }
}

struct LockContentView: View {
    let geometry: GeometryProxy
    @ObservedObject var viewModel: LockViewModel
    @FocusState private var focusedField: Int?

    var body: some View {
        VStack(spacing: 0) {
            LockHeaderView(viewModel: viewModel)
            
            VStack(spacing: 24) {
                LockTitleView()
                
                VStack(spacing: 16) {
                    LockInputSection(
                        geometry: geometry,
                        viewModel: viewModel,
                        focusedField: $focusedField
                    )
                    
                    LockGeneratedCodeView(viewModel: viewModel)
                    
                    LockCopyButton(viewModel: viewModel)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .id("lock-\(viewModel.refreshToggle)")
        .alert(isPresented: $viewModel.showingClearConfirmation) {
            Alert(
                title: Text("Clear all inputs?"),
                message: Text("All entered data will be cleared."),
                primaryButton: .destructive(Text("Yes")) {
                    viewModel.clearAllInputs()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
        .onChange(of: viewModel.focusedIndex) { 
            focusedField = viewModel.focusedIndex
        }
        .onChange(of: focusedField) { 
            viewModel.focusedIndex = focusedField
        }
    }
}

struct LockHeaderView: View {
    @ObservedObject var viewModel: LockViewModel
    
    var body: some View {
        ZStack {
            Text("Lock")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.top, 20)
                .padding(.bottom, 10)

            HStack {
                Spacer()

                Button(action: {
                    viewModel.showingClearConfirmation = true
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                }
                .padding(.trailing, 20)
            }
        }
    }
}

struct LockTitleView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Lock Code Generator")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter letters to generate lock code")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

struct LockInputSection: View {
    let geometry: GeometryProxy
    @ObservedObject var viewModel: LockViewModel
    @FocusState.Binding var focusedField: Int?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<viewModel.lockDigits, id: \.self) { index in
                    LetterInputCell(
                        letter: Binding(
                            get: { 
                                index < viewModel.enteredLetters.count ? viewModel.enteredLetters[index] : ""
                            },
                            set: { newValue in 
                                viewModel.updateLetter(at: index, with: newValue)
                            }
                        ),
                        index: index,
                        focusedField: $focusedField,
                        onSubmit: {
                            viewModel.moveToNext(from: index)
                        }
                    )
                    .frame(width: 50, height: 60)
                }
            }
            .frame(minWidth: geometry.size.width, maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
    }
}

struct LockGeneratedCodeView: View {
    @ObservedObject var viewModel: LockViewModel
    
    private var isCodeEmpty: Bool {
        viewModel.generatedCode.allSatisfy({ $0 == "_" })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Generated Code")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                if isCodeEmpty {
                    Text("Enter letters above")
                        .font(.system(size: 20, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                        .italic()
                        .multilineTextAlignment(.center)
                } else {
                    Text(viewModel.generatedCode)
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
                    .stroke(isCodeEmpty ? Color.secondary.opacity(0.3) : Color.blue.opacity(0.5), lineWidth: 2)
            )
        }
        .padding(.horizontal, 20)
    }
}

struct LockCopyButton: View {
    @ObservedObject var viewModel: LockViewModel
    
    private var isDisabled: Bool {
        viewModel.generatedCode.allSatisfy({ $0 == "_" })
    }
    
    var body: some View {
        Button(action: viewModel.copyCode) {
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
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .scaleEffect(isDisabled ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.generatedCode)
    }
}

struct LetterInputCell: View {
    @Binding var letter: String
    let index: Int
    @FocusState.Binding var focusedField: Int?
    let onSubmit: () -> Void

    var body: some View {
        TextField("", text: $letter)
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .multilineTextAlignment(.center)
            .frame(width: 50, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .stroke((focusedField == index) ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 2)
            )
            .focused($focusedField, equals: index)
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
                if focusedField == index {
                    letter = ""
                } else {
                    focusedField = index
                }
            }
    }
}