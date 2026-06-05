import SwiftUI

struct ResultView: View {
    let url: URL
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("완성된 영상")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.ink)
                Text("미리 보고 바로 저장하거나 공유할 수 있어요")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
            }

            VideoPreviewView(url: url)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                Button(action: onSave) {
                    Label("저장", systemImage: "square.and.arrow.down")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.primary)
                .background(AppTheme.softPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                ShareLink(item: url) {
                    Label("공유", systemImage: "square.and.arrow.up")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}
