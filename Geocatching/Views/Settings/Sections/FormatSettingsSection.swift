import SwiftUI

struct FormatSettingsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section(header: Text("Coordinate Formats")) {
            HStack {
                Image(systemName: "arrow.down.doc.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Input Format")
                Spacer()
                Menu {
                    ForEach(CoordinateFormat.allCases, id: \.self) { format in
                        Button(format.displayName) {
                            viewModel.setInputFormat(format)
                        }
                    }
                } label: {
                    Text(CoordinateFormat(rawValue: viewModel.defaultInputFormat)?.rawValue ?? "DD")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 5)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            HStack {
                Image(systemName: "arrow.up.doc.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Output Format")
                Spacer()
                Menu {
                    ForEach(CoordinateFormat.allCases, id: \.self) { format in
                        Button(format.displayName) {
                            viewModel.setOutputFormat(format)
                        }
                    }
                } label: {
                    Text(CoordinateFormat(rawValue: viewModel.defaultOutputFormat)?.rawValue ?? "DMS")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 5)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Default Maps")
                Spacer()
                Menu {
                    Button("Apple Maps") { viewModel.setMapService("apple") }
                    Button("Google Maps") { viewModel.setMapService("google") }
                } label: {
                    Text(viewModel.defaultMapService == "google" ? "Google" : "Apple")
                        .foregroundColor(.secondary)
                        .padding(.trailing, 5)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}