import AVFoundation
import CoreGraphics
import Foundation

private struct TimedPersonFrame {
    let time: CMTime
    let center: CGPoint
    let bodySize: CGSize
}

final class CropPlanningService {
    /// Generates display-space crop frames from sampled Vision detections.
    ///
    /// The crop is anchored to the pose-derived joint center, sized from the
    /// pose-derived body span with configurable padding, clamped inside the
    /// oriented video bounds, and smoothed to reduce jitter between samples.
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
                let center = CGRect.displayPoint(fromVisionNormalized: detection.normalizedCenter, in: videoSize)
                let targetRect = targetCropRect(
                    around: center,
                    bodySize: personRect.size,
                    cropWidthToHeight: aspectRatio.widthToHeight,
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
    /// the pose center and body span at each output frame time, then applies the
    /// same padding, aspect-ratio, clamp, and smoothing rules used by sampled plans.
    func generateFrameAlignedCropFrames(
        detections: [PersonDetection],
        videoSize: CGSize,
        duration: CMTime,
        aspectRatio: CropAspectRatio = .vertical9x16,
        cropWidthToHeight: CGFloat? = nil,
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

        let widthToHeight = cropWidthToHeight ?? aspectRatio.widthToHeight
        guard widthToHeight.isFinite, widthToHeight > 0 else {
            throw AppError.cropPlanUnavailable
        }

        let bounds = CGRect(origin: .zero, size: videoSize)
        let timedFrames = detections
            .sorted { $0.time.seconds < $1.time.seconds }
            .map { detection in
                let bodyRect = CGRect.displayRect(fromVisionNormalized: detection.normalizedBoundingBox, in: videoSize)
                return TimedPersonFrame(
                    time: detection.time,
                    center: CGRect.displayPoint(fromVisionNormalized: detection.normalizedCenter, in: videoSize),
                    bodySize: bodyRect.size
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
            let personFrame = interpolatedPersonFrame(at: frameTime, timedFrames: timedFrames)
            let targetRect = targetCropRect(
                around: personFrame.center,
                bodySize: personFrame.bodySize,
                cropWidthToHeight: widthToHeight,
                padding: padding,
                bounds: bounds
            )
            let cropRect = previousCropRect?.interpolated(to: targetRect, amount: smoothing).clamped(to: bounds) ?? targetRect
            previousCropRect = cropRect
            cropFrames.append(CropFrame(time: frameTime, cropRect: cropRect))
        }

        return cropFrames
    }

    private func interpolatedPersonFrame(at time: CMTime, timedFrames: [TimedPersonFrame]) -> TimedPersonFrame {
        guard let first = timedFrames.first else {
            return TimedPersonFrame(time: .zero, center: .zero, bodySize: .zero)
        }
        guard timedFrames.count > 1 else { return first }

        if CMTimeCompare(time, first.time) <= 0 {
            return first
        }

        for index in 1..<timedFrames.count {
            let previous = timedFrames[index - 1]
            let next = timedFrames[index]

            if CMTimeCompare(time, next.time) <= 0 {
                let duration = max(next.time.seconds - previous.time.seconds, .leastNonzeroMagnitude)
                let progress = CGFloat((time.seconds - previous.time.seconds) / duration)
                return TimedPersonFrame(
                    time: time,
                    center: previous.center.interpolated(to: next.center, amount: progress),
                    bodySize: previous.bodySize.interpolated(to: next.bodySize, amount: progress)
                )
            }
        }

        return timedFrames[timedFrames.count - 1]
    }

    private func targetCropRect(
        around center: CGPoint,
        bodySize: CGSize,
        cropWidthToHeight: CGFloat,
        padding: CGFloat,
        bounds: CGRect
    ) -> CGRect {
        let paddedWidth = max(bodySize.width * (1 + padding), 1)
        let paddedHeight = max(bodySize.height * (1 + padding), 1)

        var cropWidth = max(paddedWidth, paddedHeight * cropWidthToHeight)
        var cropHeight = cropWidth / cropWidthToHeight

        if cropHeight > bounds.height {
            cropHeight = bounds.height
            cropWidth = cropHeight * cropWidthToHeight
        }
        if cropWidth > bounds.width {
            cropWidth = bounds.width
            cropHeight = cropWidth / cropWidthToHeight
        }

        let rect = CGRect(
            x: center.x - cropWidth / 2,
            y: center.y - cropHeight / 2,
            width: cropWidth,
            height: cropHeight
        )
        return rect.clamped(to: bounds)
    }
}
