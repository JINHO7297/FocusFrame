import PhotosUI
import SwiftUI

struct VideoPickerView: View {
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .videos, photoLibrary: .shared()) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.softPrimary)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text("영상 선택하기")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text("앨범에서 크롭할 영상을 가져와요")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryInk)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
