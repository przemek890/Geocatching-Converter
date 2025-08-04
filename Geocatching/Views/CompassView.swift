import SwiftUI
import CoreLocation

struct CompassView: View {
    @ObservedObject var alphabetViewModel: AlphabetViewModel
    @StateObject private var locationManager = LocationManager()
    @AppStorage("compassLetterInputs") private var compassLetterInputsString: String = ""
    @AppStorage("compassDistanceLetterInputs") private var compassDistanceLetterInputsString: String = ""
    @State private var letterInputs: [String] = ["", "", ""]
    @State private var distanceInputs: [String] = ["", "", ""]
    @FocusState private var focusedIndex: Int?
    @State private var isCompassActive: Bool = true
    @State private var refreshToggle = false
    @State private var showingClearConfirmation = false

    private var azimuthCode: String {
        var code = ""
        for letter in letterInputs {
            if letter.isEmpty {
                code += "_"
            } else {
                let upper = letter.uppercased()
                if alphabetViewModel.currentAlphabet.contains(upper),
                   let number = alphabetViewModel.letterNumbers[upper],
                   !number.isEmpty {
                    code += number
                } else {
                    code += "_"
                }
            }
        }
        return code
    }

    private var azimuth: Int? {
        let code = azimuthCode
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

    private var azimuthText: String {
        let code = azimuthCode
        if code == "___" { return "___" }
        if let _ = azimuth {
            return code
        }
        return code
    }

    private var combinedHeading: Double {
        let deviceHeading = locationManager.heading
        if let userAzimuth = azimuth {
            return deviceHeading + Double(userAzimuth)
        }
        return deviceHeading
    }

    private var distanceCode: String {
        distanceInputs
            .reversed()
            .map { letter in
                guard !letter.isEmpty,
                      let num = alphabetViewModel.letterNumbers[letter.uppercased()],
                      !num.isEmpty
                else { return "_" }
                return num
            }
            .joined()
    }

    private var distance: Int? {
        let code = distanceCode
        if code.contains("_") { return nil }
        return Int(code)
    }

    private var distanceText: String {
        let code = distanceCode
        if code == "___" { return "___" }
        if let _ = distance {
            return code
        }
        return code
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Button(action: {
                        isCompassActive.toggle()
                        if isCompassActive {
                            locationManager.startUpdatingHeading()
                        } else {
                            locationManager.stopUpdatingHeading()
                        }
                    }) {
                        Image(systemName: isCompassActive ? "stop.fill" : "play.fill")
                            .font(.headline)
                            .foregroundColor(isCompassActive ? .red : .green)
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
                            showingClearConfirmation = true
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                        }
                        .padding(.trailing, 20)
                    }
                }

                CompassCircle(
                    azimuth: azimuth,
                    deviceHeading: locationManager.heading
                )
                .frame(width: 250, height: 250)
                .padding(.bottom, 8)

                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { idx in
                            TextField("", text: Binding(
                                get: { letterInputs[idx] },
                                set: { newValue in
                                    let filtered = newValue.uppercased().filter { $0.isLetter }
                                    let singleChar = String(filtered.prefix(1))
                                    if !letterInputs[idx].isEmpty && !singleChar.isEmpty {
                                        letterInputs[idx] = singleChar
                                        moveToNextField(from: idx, isDistance: false)
                                    } else if singleChar.isEmpty {
                                        letterInputs[idx] = ""
                                    } else {
                                        letterInputs[idx] = singleChar
                                        moveToNextField(from: idx, isDistance: false)
                                    }
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
                                get: { distanceInputs[modelIdx] },
                                set: { newValue in
                                    let filtered = newValue.uppercased().filter { $0.isLetter }
                                    let singleChar = String(filtered.prefix(1))
                                    if !distanceInputs[modelIdx].isEmpty && !singleChar.isEmpty {
                                        distanceInputs[modelIdx] = singleChar
                                        moveToNextField(from: modelIdx, isDistance: true)
                                    } else if singleChar.isEmpty {
                                        distanceInputs[modelIdx] = ""
                                    } else {
                                        distanceInputs[modelIdx] = singleChar
                                        moveToNextField(from: modelIdx, isDistance: true)
                                    }
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
                            Text(azimuthText)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
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
                            Text(distanceText)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            Text("m")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .opacity(distanceText == "X" ? 0.5 : 1)
                        }
                        .frame(width: 3 * 40 + 2 * 12, alignment: .center)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedIndex = nil
            }
            .onAppear {
                alphabetViewModel.loadLetterData()
                let chars = Array(compassLetterInputsString)
                letterInputs = (0..<3).map { i in
                    i < chars.count ? String(chars[i]) : ""
                }
                let distChars = Array(compassDistanceLetterInputsString)
                distanceInputs = (0..<3).map { i in
                    i < distChars.count ? String(distChars[i]) : ""
                }
                focusedIndex = 0
                if isCompassActive {
                    locationManager.startUpdatingHeading()
                }
            }
            .onChange(of: letterInputs) { newValue in
                compassLetterInputsString = newValue.joined()
            }
            .onChange(of: distanceInputs) { newValue in
                compassDistanceLetterInputsString = newValue.joined()
            }
            .onDisappear {
                locationManager.stopUpdatingHeading()
            }
        }
        .ignoresSafeArea(.keyboard)
        .alert(isPresented: $showingClearConfirmation) {
            Alert(
                title: Text("Clear all inputs?"),
                message: Text("All entered data will be cleared."),
                primaryButton: .destructive(Text("Yes")) {
                    resetInputs()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
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

    private func resetInputs() {
        letterInputs = ["", "", ""]
        distanceInputs = ["", "", ""]
        focusedIndex = 0
    }
}

struct CompassCircle: View {
    let azimuth: Int?
    let deviceHeading: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
            ForEach(1..<12) { i in
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 2, height: 16)
                    .offset(y: -100)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            Rectangle()
                .fill(Color.orange)
                .frame(width: 4, height: 20)
                .offset(y: -100)
                .rotationEffect(.degrees(0))
            ArrowShape()
                .fill(Color.red)
                .frame(width: 14, height: 70)
                .offset(y: -35)
                .rotationEffect(.degrees(-deviceHeading))
            if let azimuth = azimuth {
                ArrowShape()
                    .fill(Color.blue)
                    .frame(width: 18, height: 90)
                    .offset(y: -45)
                    .rotationEffect(.degrees(Double(azimuth) - deviceHeading))
                    .shadow(radius: 2)
            }
            Text("N")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.red)
                .offset(y: -120)
                .rotationEffect(.degrees(-deviceHeading))
        }
    }
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w/2, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.7))
        path.addLine(to: CGPoint(x: w/2, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * 0.7))
        path.closeSubpath()
        return path
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var heading: Double = 0.0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingHeading() {
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }

    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading.magneticHeading
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}
