import PhotosUI
import SwiftUI

struct VideoPickerView: View {
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .videos, photoLibrary: .shared()) {
            Label("Choose Video", systemImage: "photo.on.rectangle")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
    }
}

