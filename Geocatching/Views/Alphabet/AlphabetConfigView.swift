import SwiftUI

enum ActiveSheet: Identifiable {
    case photoPicker, galleryPicker, cameraPicker, imageViewer
    var id: Int { hashValue }
}

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

struct AlphabetConfigView: View {
    let alphabet: [String]
    @Binding var letterNumbers: [String: String]
    @Binding var letterImages: [String: Data]
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedLetter = ""
    @State private var viewerImage: UIImage?
    @State private var activeSheet: ActiveSheet?

    private let columns = [ GridItem(.adaptive(minimum: 100), spacing: 16) ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(alphabet, id: \.self) { letter in
                    LetterCardView(
                        letter: letter,
                        number: Binding(
                            get: { letterNumbers[letter] ?? "" },
                            set: { letterNumbers[letter] = $0.isEmpty ? nil : $0 }
                        ),
                        imageData: Binding(
                            get: { letterImages[letter] },
                            set: { letterImages[letter] = $0 }
                        ),
                        onImageTap: { hasImage in
                            selectedLetter = letter
                            if hasImage, let data = letterImages[letter], let img = UIImage(data: data) {
                                viewerImage = img
                                activeSheet = .imageViewer
                            } else {
                                activeSheet = .photoPicker
                            }
                        }
                    )
                }
            }
            .padding(16)
        }
        .onTapGesture { hideKeyboard() }
        .navigationTitle("Letter Codes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { item in
            switch item {
            case .photoPicker:
                ActionSheetPhotoSource(onSelect: { source in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        activeSheet = (source == .camera ? .cameraPicker : .galleryPicker)
                    }
                })
            case .galleryPicker:
                ImagePicker(sourceType: .photoLibrary) { img in
                    saveImage(for: selectedLetter, img)
                    selectedLetter = ""
                }
            case .cameraPicker:
                ImagePicker(sourceType: .camera) { img in
                    saveImage(for: selectedLetter, img)
                    selectedLetter = ""
                }
            case .imageViewer:
                if let img = viewerImage {
                    CustomImageViewerView(
                        image: img,
                        letter: selectedLetter,
                        showTrashIcon: true,
                        onDelete: {
                            letterImages[selectedLetter] = nil
                            activeSheet = nil
                        }
                    )
                }
            }
        }
        .onChange(of: activeSheet) { new in
            if new == nil {
                viewerImage = nil
            }
        }
        .onChange(of: letterImages) { _ in
            onSave()
        }
        .onChange(of: letterNumbers) { _ in
            onSave()
        }
        .onAppear { }
    }

    func saveImage(for letter: String, _ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            letterImages[letter] = data
            onSave()
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
