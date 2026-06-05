import AVFoundation
import CoreGraphics
import Foundation
import Vision

final class VisionPersonDetectionService {
    private let sampleFPS: Double
    private static let minimumJointConfidence: Float = 0.2

    init(sampleFPS: Double = 5) {
        self.sampleFPS = sampleFPS
    }

    /// Samples the video at a fixed FPS and runs Vision human body pose estimation.
    ///
    /// `VNDetectHumanBodyPoseRequest` returns normalized joint coordinates rather
    /// than object-detection rectangles. For each pose observation this service
    /// filters reliable joints, builds a pose-derived body span, and stores the
    /// average joint center as the camera framing anchor.
    func detectPeople(
        in video: VideoAsset,
        progress: @escaping ProgressHandler
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

                if let detection = try Self.detectLargestPersonPose(in: image, at: actualTime) {
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

    private static func detectLargestPersonPose(in image: CGImage, at time: CMTime) throws -> PersonDetection? {
        let request = VNDetectHumanBodyPoseRequest()

        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
        try handler.perform([request])

        return try request.results?
            .compactMap { try detection(from: $0, at: time) }
            .max { $0.area < $1.area }
    }

    private static func detection(
        from observation: VNHumanBodyPoseObservation,
        at time: CMTime
    ) throws -> PersonDetection? {
        let recognizedPoints = try observation.recognizedPoints(.all)
        let reliablePoints = recognizedPoints.values
            .filter { $0.confidence >= minimumJointConfidence }

        guard !reliablePoints.isEmpty else {
            return nil
        }

        let points = reliablePoints.map { clampNormalized($0.location) }
        let minX = points.map(\.x).min() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxX = points.map(\.x).max() ?? minX
        let maxY = points.map(\.y).max() ?? minY
        let summedPoint = points.reduce(CGPoint.zero) { partial, point in
            CGPoint(x: partial.x + point.x, y: partial.y + point.y)
        }
        let jointCount = CGFloat(points.count)
        let center = CGPoint(x: summedPoint.x / jointCount, y: summedPoint.y / jointCount)
        let averageConfidence = reliablePoints.reduce(Float.zero) { $0 + $1.confidence } / Float(reliablePoints.count)

        return PersonDetection(
            time: time,
            normalizedBoundingBox: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY),
            normalizedCenter: center,
            confidence: averageConfidence,
            jointCount: points.count
        )
    }

    private static func clampNormalized(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), 1),
            y: min(max(point.y, 0), 1)
        )
    }
}
