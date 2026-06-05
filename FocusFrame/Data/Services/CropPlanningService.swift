import AVFoundation
import CoreGraphics
import Foundation

private struct TimedPersonRect {
    let time: CMTime
    let rect: CGRect
}

final class CropPlanningService {
    /// Generates display-space crop frames from sampled Vision detections.
    ///
    /// The crop is centered around the detected person with configurable padding,
    /// forced to the requested aspect ratio, clamped inside the oriented video
    /// bounds, and smoothed to reduce jitter between sampled detections.
    func generateCropFrames(
        detections: [PersonDetection],
        videoSize: CGSize,
        aspectRatio: CropAspectRatio = .vertical9x16,
        padding: CGFloat = 0.55,
        smoothing: CGFloat = 0.28
    ) throws -> [CropFrame] {
        guard !detections.isEmpty, videoSize.width > 0, videoSize.height > 0 else {
            throw AppError.cropPlanUnavailable
        }

        let bounds = CGRect(origin: .zero, size: videoSize)
        var previousRect: CGRect?

        return detections
            .sorted { $0.time.seconds < $1.time.seconds }
            .map { detection in
                let personRect = CGRect.displayRect(fromVisionNormalized: detection.normalizedBoundingBox, in: videoSize)
                let targetRect = targetCropRect(
                    around: personRect,
                    aspectRatio: aspectRatio,
                    padding: padding,
                    bounds: bounds
                )
                let smoothedRect = previousRect?.interpolated(to: targetRect, amount: smoothing).clamped(to: bounds) ?? targetRect
                previousRect = smoothedRect
                return CropFrame(time: detection.time, cropRect: smoothedRect)
            }
    }

    /// Expands sampled Vision detections into a crop frame for every output video frame.
    ///
    /// Vision analysis may run at a lower sampling rate for performance, but export
    /// needs a continuous per-frame crop timeline so the crop window follows the
    /// person instead of jumping between sparse detections. This method interpolates
    /// the detected person rectangle at each output frame time, then applies the
    /// same padding, aspect-ratio, clamp, and smoothing rules used by sampled plans.
    func generateFrameAlignedCropFrames(
        detections: [PersonDetection],
        videoSize: CGSize,
        duration: CMTime,
        aspectRatio: CropAspectRatio = .vertical9x16,
        padding: CGFloat = 0.55,
        smoothing: CGFloat = 0.45,
        outputFrameRate: Double = 30
    ) throws -> [CropFrame] {
        guard !detections.isEmpty,
              videoSize.width > 0,
              videoSize.height > 0,
              duration.seconds.isFinite,
              duration.seconds >= 0,
              outputFrameRate > 0
        else {
            throw AppError.cropPlanUnavailable
        }

        let bounds = CGRect(origin: .zero, size: videoSize)
        let timedRects = detections
            .sorted { $0.time.seconds < $1.time.seconds }
            .map {
                TimedPersonRect(
                    time: $0.time,
                    rect: CGRect.displayRect(fromVisionNormalized: $0.normalizedBoundingBox, in: videoSize)
                )
            }

        let durationSeconds = duration.seconds
        let lastFrameIndex = max(0, Int((durationSeconds * outputFrameRate).rounded(.up)))
        var previousCropRect: CGRect?
        var cropFrames: [CropFrame] = []
        cropFrames.reserveCapacity(lastFrameIndex + 1)

        for frameIndex in 0...lastFrameIndex {
            let seconds = min(Double(frameIndex) / outputFrameRate, durationSeconds)
            let frameTime = CMTime(seconds: seconds, preferredTimescale: 600)
            let personRect = interpolatedPersonRect(at: frameTime, timedRects: timedRects)
            let targetRect = targetCropRect(
                around: personRect,
                aspectRatio: aspectRatio,
                padding: padding,
                bounds: bounds
            )
            let cropRect = previousCropRect?.interpolated(to: targetRect, amount: smoothing).clamped(to: bounds) ?? targetRect
            previousCropRect = cropRect
            cropFrames.append(CropFrame(time: frameTime, cropRect: cropRect))
        }

        return cropFrames
    }

    private func interpolatedPersonRect(at time: CMTime, timedRects: [TimedPersonRect]) -> CGRect {
        guard let first = timedRects.first else { return .zero }
        guard timedRects.count > 1 else { return first.rect }

        if CMTimeCompare(time, first.time) <= 0 {
            return first.rect
        }

        for index in 1..<timedRects.count {
            let previous = timedRects[index - 1]
            let next = timedRects[index]

            if CMTimeCompare(time, next.time) <= 0 {
                let duration = max(next.time.seconds - previous.time.seconds, .leastNonzeroMagnitude)
                let progress = CGFloat((time.seconds - previous.time.seconds) / duration)
                return previous.rect.interpolated(to: next.rect, amount: progress)
            }
        }

        return timedRects[timedRects.count - 1].rect
    }

    private func targetCropRect(
        around personRect: CGRect,
        aspectRatio: CropAspectRatio,
        padding: CGFloat,
        bounds: CGRect
    ) -> CGRect {
        let paddedWidth = personRect.width * (1 + padding)
        let paddedHeight = personRect.height * (1 + padding)
        let widthToHeight = aspectRatio.widthToHeight

        var cropWidth = max(paddedWidth, paddedHeight * widthToHeight)
        var cropHeight = cropWidth / widthToHeight

        if cropHeight > bounds.height {
            cropHeight = bounds.height
            cropWidth = cropHeight * widthToHeight
        }
        if cropWidth > bounds.width {
            cropWidth = bounds.width
            cropHeight = cropWidth / widthToHeight
        }

        let center = CGPoint(x: personRect.midX, y: personRect.midY)
        let rect = CGRect(
            x: center.x - cropWidth / 2,
            y: center.y - cropHeight / 2,
            width: cropWidth,
            height: cropHeight
        )
        return rect.clamped(to: bounds)
    }
}
