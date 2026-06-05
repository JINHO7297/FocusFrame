import Foundation
import Photos

final class PhotoLibrarySaveService {
    /// Saves an exported movie into the user's Photo Library after requesting
    /// add-only authorization.
    func saveVideo(at url: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw AppError.photoLibraryDenied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
        } catch {
            throw AppError.saveFailed(error.localizedDescription)
        }
    }
}

