import SwiftUI

struct LetterButtonView: View {
    let letter: String
    let number: String?
    let hasImage: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(letter)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                if let number = number, !number.isEmpty {
                    Text(number)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                if hasImage {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}