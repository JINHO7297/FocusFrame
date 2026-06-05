import AVFoundation
import CoreGraphics
import Foundation

final class VideoExportService {
    /// Exports a new video by applying time-varying layer transforms that map each
    /// planned crop rectangle into the fixed output canvas. Audio tracks are copied
    /// into the composition unchanged.
    func export(
        video: VideoAsset,
        cropFrames: [CropFrame],
        aspectRatio: CropAspectRatio = .vertical9x16,
        progress: @escaping @Sendable (Double) async -> Void
    ) async throws -> URL {
        guard !cropFrames.isEmpty else {
            throw AppError.cropPlanUnavailable
        }

        let sourceAsset = AVURLAsset(url: video.url)
        let duration = try await sourceAsset.load(.duration)
        guard let sourceVideoTrack = try await sourceAsset.loadTracks(withMediaType: .video).first else {
            throw AppError.noVideoTrack
        }

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw AppError.exportSessionUnavailable
        }

        let fullRange = CMTimeRange(start: .zero, duration: duration)
        try compositionVideoTrack.insertTimeRange(fullRange, of: sourceVideoTrack, at: .zero)
        compositionVideoTrack.preferredTransform = .identity

        let audioTracks = try await sourceAsset.loadTracks(withMediaType: .audio)
        for audioTrack in audioTracks {
            if let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) {
                try compositionAudioTrack.insertTimeRange(fullRange, of: audioTrack, at: .zero)
            }
        }

        let naturalSize = try await sourceVideoTrack.load(.naturalSize)
        let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
        let displayTransform = VideoGeometry.displayTransform(
            naturalSize: naturalSize,
            preferredTransform: preferredTransform
        )

        let outputSize = aspectRatio.defaultOutputSize
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = outputSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = makeInstructions(
            track: compositionVideoTrack,
            cropFrames: cropFrames,
            duration: duration,
            displayTransform: displayTransform,
            outputSize: outputSize
        )

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw AppError.exportSessionUnavailable
        }

        let outputURL = FileManagerHelper.exportURL(fileExtension: "mp4")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition

        let progressTask = Task {
            while !Task.isCancelled {
                switch exportSession.status {
                case .waiting, .exporting:
                    await progress(Double(exportSession.progress))
                    try? await Task.sleep(nanoseconds: 200_000_000)
                default:
                    await progress(Double(exportSession.progress))
                    return
                }
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportSession.exportAsynchronously {
                progressTask.cancel()
                switch exportSession.status {
                case .completed:
                    continuation.resume()
                case .cancelled:
                    continuation.resume(throwing: AppError.cancelled)
                case .failed:
                    continuation.resume(throwing: AppError.exportFailed(exportSession.error?.localizedDescription ?? "Unknown error"))
                default:
                    continuation.resume(throwing: AppError.exportFailed("Unexpected export status \(exportSession.status.rawValue)"))
                }
            }
        }

        await progress(1)
        return outputURL
    }

    private func makeInstructions(
        track: AVCompositionTrack,
        cropFrames: [CropFrame],
        duration: CMTime,
        displayTransform: CGAffineTransform,
        outputSize: CGSize
    ) -> [AVMutableVideoCompositionInstruction] {
        var timeline = cropFrames.sorted { $0.time.seconds < $1.time.seconds }

        if let first = timeline.first, CMTimeCompare(first.time, .zero) > 0 {
            timeline.insert(CropFrame(time: .zero, cropRect: first.cropRect), at: 0)
        }
        if let last = timeline.last, CMTimeCompare(last.time, duration) < 0 {
            timeline.append(CropFrame(time: duration, cropRect: last.cropRect))
        }

        guard timeline.count > 1 else {
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            let rect = timeline.first?.cropRect ?? CGRect(origin: .zero, size: outputSize)
            layerInstruction.setTransform(renderTransform(for: rect, displayTransform: displayTransform, outputSize: outputSize), at: .zero)
            instruction.layerInstructions = [layerInstruction]
            return [instruction]
        }

        return (0..<(timeline.count - 1)).compactMap { index in
            let current = timeline[index]
            let next = timeline[index + 1]
            let segmentDuration = CMTimeSubtract(next.time, current.time)
            guard CMTimeCompare(segmentDuration, .zero) > 0 else {
                return nil
            }

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: current.time, duration: segmentDuration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            let startTransform = renderTransform(for: current.cropRect, displayTransform: displayTransform, outputSize: outputSize)
            let endTransform = renderTransform(for: next.cropRect, displayTransform: displayTransform, outputSize: outputSize)
            layerInstruction.setTransformRamp(
                fromStart: startTransform,
                toEnd: endTransform,
                timeRange: instruction.timeRange
            )
            instruction.layerInstructions = [layerInstruction]
            return instruction
        }
    }

    private func renderTransform(
        for cropRect: CGRect,
        displayTransform: CGAffineTransform,
        outputSize: CGSize
    ) -> CGAffineTransform {
        let scale = outputSize.width / cropRect.width
        return displayTransform
            .concatenating(CGAffineTransform(translationX: -cropRect.minX, y: -cropRect.minY))
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
    }
}

