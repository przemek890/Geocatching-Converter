import SwiftUI
import Combine

struct CompassView: View {
    @StateObject private var viewModel: CompassViewModel
    @FocusState private var focusedIndex: Int?
    
    init(alphabetViewModel: AlphabetViewModel, settingsViewModel: SettingsViewModel) {
        let locationService = LocationService()
        _viewModel = StateObject(wrappedValue: CompassViewModel(
            alphabetViewModel: alphabetViewModel,
            locationService: locationService,
            settingsViewModel: settingsViewModel
        ))
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                headerView
                
                CompassCircle(compassData: viewModel.compassData)
                    .frame(width: 250, height: 250)
                    .padding(.bottom, 8)
                
                inputFieldsView
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.dismissFocus()
                focusedIndex = nil
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            viewModel.startCompassIfActive()
            viewModel.recalculateCompassData()
        }
        .onDisappear {
            viewModel.stopCompass()
        }
        .onChange(of: viewModel.focusedIndex) { newValue in
            focusedIndex = newValue
        }
        .onChange(of: focusedIndex) { newValue in
            viewModel.focusedIndex = newValue
        }
        .alert(isPresented: $viewModel.showingClearConfirmation) {
            Alert(
                title: Text("Clear all inputs?"),
                message: Text("All entered data will be cleared."),
                primaryButton: .destructive(Text("Yes")) {
                    viewModel.clearInputs()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                viewModel.toggleCompass()
            }) {
                Image(systemName: viewModel.locationService.isActive ? "stop.fill" : "play.fill")
                    .font(.headline)
                    .foregroundColor(viewModel.locationService.isActive ? .red : .green)
                    .padding(8)
            }
            .padding(.leading, 8)
            
            HStack {
                Text("Compass")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                Button(action: {
                    viewModel.showClearConfirmation()
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
    
    private var inputFieldsView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { idx in
                    TextField("", text: Binding(
                        get: { viewModel.letterInputs[idx] },
                        set: { newValue in
                            viewModel.updateLetterInput(at: idx, with: newValue)
                        }
                    ))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 40, height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedIndex == idx ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 2))
                    .focused($focusedIndex, equals: idx)
                }
                
                Text("|")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                ForEach(0..<3, id: \.self) { uiIdx in
                    let modelIdx = 2 - uiIdx
                    TextField("", text: Binding(
                        get: { viewModel.distanceInputs[modelIdx] },
                        set: { newValue in
                            viewModel.updateDistanceInput(at: modelIdx, with: newValue)
                        }
                    ))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 40, height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(focusedIndex == modelIdx + 3 ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 2))
                    .focused($focusedIndex, equals: modelIdx + 3)
                }
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Azimuth:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(viewModel.compassData.azimuthText)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .id(viewModel.compassData.azimuthText)
                }
                .frame(width: 3 * 40 + 2 * 12, alignment: .center)
                
                Text("|")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                HStack(spacing: 8) {
                    Text("Distance:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(viewModel.compassData.distanceText)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .id(viewModel.compassData.distanceText) 
                    Text("m")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .opacity(viewModel.compassData.distanceText == "___" ? 0.5 : 1)
                }
                .frame(width: 3 * 40 + 2 * 12, alignment: .center)
            }
        }
    }
}