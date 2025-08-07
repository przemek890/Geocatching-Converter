import SwiftUI

struct ActionSheetPhotoSource: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (UIImagePickerController.SourceType) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose photo source")
                .font(.headline)
                .padding(.top, 24)

            Button {
                onSelect(.camera)
                dismiss()
            } label: {
                Label("Camera", systemImage: "camera")
                    .font(.title2)
            }
            .padding()

            Button {
                onSelect(.photoLibrary)
                dismiss()
            } label: {
                Label("Gallery", systemImage: "photo")
                    .font(.title2)
            }
            .padding()

            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.red)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
}