import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let card = Color.white
    static let primary = Color(red: 0.12, green: 0.39, blue: 0.96)
    static let softPrimary = Color(red: 0.90, green: 0.94, blue: 1.00)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let secondaryInk = Color(red: 0.42, green: 0.46, blue: 0.52)
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(title)
                    .font(.headline.weight(.semibold))
            }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(.white)
                .background(isDisabled ? Color(.systemGray4) : AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
