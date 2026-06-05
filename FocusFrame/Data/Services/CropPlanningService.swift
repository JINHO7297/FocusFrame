import CoreGraphics
import Foundation

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

