import Foundation

final class ExportCroppedVideoUseCase {
    private let exportService: VideoExportService

    init(exportService: VideoExportService = VideoExportService()) {
        self.exportService = exportService
    }

    func execute(
        video: VideoAsset,
        cropFrames: [CropFrame],
        aspectRatio: CropAspectRatio = .vertical9x16,
        progress: @escaping ProgressHandler
    ) async throws -> URL {
        try await exportService.export(
            video: video,
            cropFrames: cropFrames,
            aspectRatio: aspectRatio,
            progress: progress
        )
    }
}
