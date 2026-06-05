import Foundation
import PhotosUI

@MainActor
final class VideoPickerViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
}

