import SwiftUI

struct CoordinateInputView: View {
    @Binding var coordinate: Coordinate
    let format: CoordinateFormat
    let isLatitude: Bool
    let onFieldComplete: () -> Void
    var isFocused: FocusState<Bool>.Binding?
    
    @State private var degreesText: String = ""
    @State private var decimalText: String = ""
    @State private var minutesText: String = ""
    @State private var decimalMinutesText: String = ""
    @State private var secondsText: String = ""
    @State private var forceRefresh: Bool = false
    @FocusState private var focusedField: InputField?

    
    enum InputField {
        case degrees, decimal, minutes, decimalMinutes, seconds
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Menu {
                ForEach(isLatitude ? [CoordinateDirection.north, .south] : [.east, .west], id: \.self) { direction in
                    Button(direction.rawValue) {
                        coordinate.direction = direction
                    }
                }
            } label: {
                Text(coordinate.direction.rawValue)
                    .frame(width: 25, height: 32)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(6)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            }
            
            switch format {
            case .dd:
                ddInputFields()
            case .ddm:
                ddmInputFields()
            case .dms:
                dmsInputFields()
            }
            
            Spacer()
        }
        .onAppear {
            updateTextFields()
            
            NotificationCenter.default.addObserver(
                forName: Notification.Name("CoordinatesChanged"),
                object: nil,
                queue: .main
            ) { _ in
                updateTextFields()
                forceRefresh.toggle()
            }
        }
        .id("coordinate-\(forceRefresh)-\(coordinate.direction.rawValue)-\(format.rawValue)") // Wymusi odświeżenie przy zmianie
        .onChange(of: format) { _ in
            updateTextFields()
        }
        .onChange(of: coordinate) { _ in
            updateTextFields()
        }
    }
    
    @ViewBuilder
    private func ddInputFields() -> some View {
        HStack(spacing: 3) {
            TextField(isLatitude ? "00" : "000", text: $degreesText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: isLatitude ? 35 : 40, height: 32)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .focused($focusedField, equals: .degrees)
                .onChange(of: degreesText) { _ in
                    let maxDigits = isLatitude ? 2 : 3
                    if degreesText.count >= maxDigits {
                        focusedField = .decimal
                    }
                    updateCoordinateFromDD()
                }
                .onChange(of: isFocused?.wrappedValue ?? false) { shouldFocus in
                    if shouldFocus && isLatitude {
                        focusedField = .degrees
                    }
                }
                .onSubmit {
                    let degrees = Int(degreesText) ?? 0
                    let maxDigits = isLatitude ? 2 : 3
                    if degreesText.count < maxDigits {
                        degreesText = String(format: isLatitude ? "%02d" : "%03d", degrees)
                    }
                    focusedField = .decimal
                }
            
            Text(".")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            TextField("00000", text: $decimalText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 60, height: 32)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .focused($focusedField, equals: .decimal)
                .onChange(of: decimalText) { _ in
                    updateCoordinateFromDD()
                }
                .onSubmit {
                    onFieldComplete()
                }
        }
    }
    
    @ViewBuilder
    private func ddmInputFields() -> some View {
        HStack(spacing: 3) {
            TextField(isLatitude ? "00" : "000", text: $degreesText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: isLatitude ? 35 : 40, height: 32)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .focused($focusedField, equals: .degrees)
                .onChange(of: degreesText) { _ in
                    let maxDigits = isLatitude ? 2 : 3
                    if degreesText.count >= maxDigits {
                        focusedField = .decimalMinutes
                    }
                    updateCoordinateFromDDM()
                }
                .onChange(of: isFocused?.wrappedValue ?? false) { shouldFocus in
                    if shouldFocus && isLatitude {
                        focusedField = .degrees
                    }
                }
                .onSubmit {
                    let degrees = Int(degreesText) ?? 0
                    let maxDigits = isLatitude ? 2 : 3
                    if degreesText.count < maxDigits {
                        degreesText = String(format: isLatitude ? "%02d" : "%03d", degrees)
                    }
                    focusedField = .decimalMinutes
                }
            
            TextField("00.000", text: $decimalMinutesText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 75, height: 32)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .focused($focusedField, equals: .decimalMinutes)
                .onChange(of: decimalMinutesText) { newValue in
                    if !newValue.contains(".") && newValue.count > 2 {
                        let firstTwo = String(newValue.prefix(2))
                        let rest = String(newValue.dropFirst(2))
                        decimalMinutesText = firstTwo + "." + rest
                    }
                    updateCoordinateFromDDM()
                }
                .onSubmit {
                    onFieldComplete()
                }
        }
    }
    
    @ViewBuilder
    private func dmsInputFields() -> some View {
        HStack(spacing: 3) {
            TextField(isLatitude ? "00" : "000", text: $degreesText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: isLatitude ? 35 : 40, height: 32)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .focused($focusedField, equals: .degrees)
                .onChange(of: degreesText) { _ in
                    let maxDigits = isLatitude ? 2 : 3
                    if degreesText.count >= maxDigits {
                        focusedField = .minutes
                    }
                    updateCoordinateFromDMS()
                }
                .onChange(of: isFocused?.wrappedValue ?? false) { shouldFocus in
                    if shouldFocus && isLatitude {
                        focusedField = .degrees
                    }
                }
                .onSubmit {
                    let degrees = Int(degreesText) ?? 0
                    let maxDigits = isLatitude ? 2 : 3
                    if degreesText.count < maxDigits {
                        degreesText = String(format: isLatitude ? "%02d" : "%03d", degrees)
                    }
                    focusedField = .minutes
                }
            
            TextField("00", text: $minutesText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 35, height: 32)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .focused($focusedField, equals: .minutes)
                .onChange(of: minutesText) { _ in
                    if minutesText.count >= 2 {
                        focusedField = .seconds
                    }
                    updateCoordinateFromDMS()
                }
                .onSubmit {
                    let minutes = Int(minutesText) ?? 0
                    if minutesText.count < 2 {
                        minutesText = String(format: "%02d", minutes)
                    }
                    focusedField = .seconds
                }
            
            TextField("00", text: $secondsText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 35, height: 32)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .focused($focusedField, equals: .seconds)
                .onChange(of: secondsText) { _ in
                    updateCoordinateFromDMS()
                }
                .onSubmit {
                    let seconds = Int(secondsText) ?? 0
                    if secondsText.count < 2 {
                        secondsText = String(format: "%02d", seconds)
                    }
                    onFieldComplete()
                }
        }
    }
    
    private func updateTextFields() {
        switch format {
        case .dd:
            let degrees = coordinate.degrees
            let decimal = coordinate.decimalDegrees - Double(degrees)
            degreesText = degrees > 0 ? String(format: isLatitude ? "%02d" : "%03d", degrees) : ""
            if decimal > 0 {
                let decimalString = String(format: "%.5f", decimal)
                decimalText = String(decimalString.dropFirst(2))
            } else {
                decimalText = ""
            }
        case .ddm:
            degreesText = coordinate.degrees > 0 ? String(format: isLatitude ? "%02d" : "%03d", coordinate.degrees) : ""
            decimalMinutesText = coordinate.decimalMinutes > 0 ? String(format: "%.3f", coordinate.decimalMinutes) : ""
        case .dms:
            degreesText = coordinate.degrees > 0 ? String(format: isLatitude ? "%02d" : "%03d", coordinate.degrees) : ""
            minutesText = coordinate.minutes > 0 ? String(format: "%02d", coordinate.minutes) : ""
            secondsText = coordinate.seconds > 0 ? String(format: "%02d", coordinate.seconds) : ""
        }
    }
    
    private func updateCoordinateFromDD() {
        let degrees = Int(degreesText) ?? 0
        let decimal = Double("0." + decimalText) ?? 0.0
        let totalDecimal = Double(degrees) + decimal
        
        coordinate.degrees = degrees
        coordinate.decimalDegrees = totalDecimal
        
        let minutesDecimal = decimal * 60.0
        coordinate.decimalMinutes = minutesDecimal
        coordinate.minutes = Int(minutesDecimal)
        coordinate.seconds = Int((minutesDecimal - Double(coordinate.minutes)) * 60.0)
    }
    
    private func updateCoordinateFromDDM() {
        coordinate.degrees = Int(degreesText) ?? 0
        coordinate.decimalMinutes = Double(decimalMinutesText) ?? 0.0
        coordinate.minutes = Int(coordinate.decimalMinutes)
        coordinate.seconds = Int((coordinate.decimalMinutes - Double(coordinate.minutes)) * 60.0)
        coordinate.decimalDegrees = Double(coordinate.degrees) + coordinate.decimalMinutes / 60.0
    }
    
    private func updateCoordinateFromDMS() {
        coordinate.degrees = Int(degreesText) ?? 0
        coordinate.minutes = Int(minutesText) ?? 0
        coordinate.seconds = Int(secondsText) ?? 0
        coordinate.decimalMinutes = Double(coordinate.minutes) + Double(coordinate.seconds) / 60.0
        coordinate.decimalDegrees = Double(coordinate.degrees) + coordinate.decimalMinutes / 60.0
    }
    
    func clearFields() {
        degreesText = ""
        decimalText = ""
        minutesText = ""
        decimalMinutesText = ""
        secondsText = ""
        coordinate.degrees = 0
        coordinate.decimalDegrees = 0
        coordinate.minutes = 0
        coordinate.seconds = 0
        coordinate.decimalMinutes = 0
        coordinate.direction = isLatitude ? .north : .east
    }
}
