import AVFoundation
import Foundation

final class VideoMetadataService {
    /// Reads AVFoundation metadata needed by the UI and downstream crop pipeline.
    /// Display size is orientation-aware, unlike `naturalSize`, which is stored in
    /// encoded track coordinates.
    func metadata(for url: URL) async throws -> VideoAsset {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw AppError.noVideoTrack
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let displaySize = VideoGeometry.displaySize(naturalSize: naturalSize, preferredTransform: preferredTransform)

        return VideoAsset(
            url: url,
            fileName: url.fileDisplayName,
            duration: duration,
            naturalSize: naturalSize,
            displaySize: displaySize,
            fileSizeInBytes: url.fileSizeInBytes
        )
    }
}

