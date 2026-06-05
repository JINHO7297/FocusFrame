import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class VideoPickerViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
}
