import Foundation

final class ExportCroppedVideoUseCase {
    private let exportService: VideoExportService

    init(exportService: VideoExportService = VideoExportService()) {
        self.exportService = exportService
    }

    func execute(
        video: VideoAsset,
        cropFrames: [CropFrame],
        progress: @escaping ProgressHandler
    ) async throws -> URL {
        try await exportService.export(
            video: video,
            cropFrames: cropFrames,
            progress: progress
        )
    }
}
