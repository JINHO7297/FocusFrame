import AVFoundation
import CoreGraphics
import Foundation
import Vision

final class VisionPersonDetectionService {
    private let sampleFPS: Double

    init(sampleFPS: Double = 5) {
        self.sampleFPS = sampleFPS
    }

    /// Samples the video at a fixed FPS and runs Vision human rectangle detection
    /// on each generated frame. The largest bounding box per frame becomes the
    /// MVP target for that timestamp.
    func detectPeople(
        in video: VideoAsset,
        progress: @escaping @Sendable (Double) async -> Void
    ) async throws -> [PersonDetection] {
        try await Task.detached(priority: .userInitiated) { [sampleFPS] in
            let asset = AVURLAsset(url: video.url)
            let duration = try await asset.load(.duration)
            let durationSeconds = max(duration.seconds, 0)
            let frameCount = max(1, Int((durationSeconds * sampleFPS).rounded(.up)))

            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = CMTime(seconds: 0.08, preferredTimescale: 600)
            generator.requestedTimeToleranceAfter = CMTime(seconds: 0.08, preferredTimescale: 600)

            var detections: [PersonDetection] = []
            detections.reserveCapacity(frameCount)

            for index in 0..<frameCount {
                try Task.checkCancellation()
                let seconds = min(durationSeconds, Double(index) / sampleFPS)
                let requestedTime = CMTime(seconds: seconds, preferredTimescale: 600)
                var actualTime = CMTime.zero
                let image = try generator.copyCGImage(at: requestedTime, actualTime: &actualTime)

                if let detection = try Self.detectLargestPerson(in: image, at: actualTime) {
                    detections.append(detection)
                }

                await progress(Double(index + 1) / Double(frameCount))
            }

            guard !detections.isEmpty else {
                throw AppError.noPersonDetected
            }
            return detections
        }.value
    }

    private static func detectLargestPerson(in image: CGImage, at time: CMTime) throws -> PersonDetection? {
        let request = VNDetectHumanRectanglesRequest()
        request.upperBodyOnly = false

        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
        try handler.perform([request])

        guard let observation = request.results?.max(by: { $0.boundingBox.area < $1.boundingBox.area }) else {
            return nil
        }

        return PersonDetection(
            time: time,
            normalizedBoundingBox: observation.boundingBox,
            confidence: observation.confidence
        )
    }
}

