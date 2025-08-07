import SwiftUI

struct LockSettingsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(header: Text("Lock Settings")) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Lock Digits")
                Spacer()
                Text("\(viewModel.lockDigits)")
                    .foregroundColor(.secondary)
                    .font(.body)
                Stepper("", value: Binding(
                    get: { viewModel.lockDigits },
                    set: { viewModel.setLockDigits($0) }
                ), in: 3...10)
                .labelsHidden()
            }
            .padding(.vertical, 4)
        }
    }
}