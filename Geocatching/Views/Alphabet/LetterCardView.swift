import SwiftUI
import UIKit

extension UIApplication {
    func hideKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LetterCardView: View {
    let letter: String
    @Binding var number: String
    @Binding var imageData: Data?
    let onImageTap: (Bool) -> Void

    @State private var didDismissKeyboard = false

    var body: some View {
        VStack(spacing: 10) {
            Text(letter)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding(.top, 4)

            TextField("Number", text: $number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal, 4)

            Button(action: {
                if didDismissKeyboard {
                    onImageTap(imageData != nil)
                } else {
                    UIApplication.shared.hideKeyboard()
                    didDismissKeyboard = true
                }
            }) {
                if let imageData = imageData,
                   let uiImage = UIImage(data: imageData) {
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .foregroundColor(.blue)
                            .offset(x: 25, y: -25)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 70, height: 70)
                        VStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Add")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .animation(.easeInOut, value: imageData != nil)
        .onTapGesture {
            UIApplication.shared.hideKeyboard()
            didDismissKeyboard = false
        }
    }
}
