import SwiftUI

struct NotesSettingsSection: View {
    @AppStorage("generalNote") private var generalNote: String = ""
    @State private var isSheetPresented = false

    var body: some View {
        Button {
            isSheetPresented = true
        } label: {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                    .font(.system(size: 16))
                Text("Notes")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $isSheetPresented) {
            NotesEditorView(note: $generalNote)
        }
    }
}

struct NotesEditorView: View {
    @Binding var note: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $note)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .navigationTitle("Notes")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .padding()
        }
    }
}