import CoreTransferable
import Foundation
import PhotosUI
import UniformTypeIdentifiers

struct PickedVideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let fileExtension = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let copyURL = FileManagerHelper.temporaryURL(fileExtension: fileExtension)
            try FileManagerHelper.replaceItemIfNeeded(from: received.file, to: copyURL)
            return PickedVideoFile(url: copyURL)
        }
    }
}

final class PickVideoUseCase {
    private let metadataService: VideoMetadataService

    init(metadataService: VideoMetadataService = VideoMetadataService()) {
        self.metadataService = metadataService
    }

    func execute(item: PhotosPickerItem) async throws -> VideoAsset {
        guard let file = try await item.loadTransferable(type: PickedVideoFile.self) else {
            throw AppError.videoSelectionFailed
        }
        return try await metadataService.metadata(for: file.url)
    }
}

