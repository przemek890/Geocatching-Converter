import SwiftUI

struct AppInfoSection: View {
    var body: some View {
        Section {
            VStack(spacing: 0) {
                Text("Version 1.2.1")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
            .padding(.top, -25)
        }
    }
}