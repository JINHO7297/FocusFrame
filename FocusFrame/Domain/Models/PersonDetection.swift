import AVFoundation
import CoreGraphics
import Foundation

struct PersonDetection: Identifiable, Equatable {
    let id = UUID()
    let time: CMTime
    let normalizedBoundingBox: CGRect
    let normalizedCenter: CGPoint
    let confidence: Float
    let jointCount: Int

    init(
        time: CMTime,
        normalizedBoundingBox: CGRect,
        normalizedCenter: CGPoint? = nil,
        confidence: Float,
        jointCount: Int = 0
    ) {
        self.time = time
        self.normalizedBoundingBox = normalizedBoundingBox
        self.normalizedCenter = normalizedCenter ?? CGPoint(
            x: normalizedBoundingBox.midX,
            y: normalizedBoundingBox.midY
        )
        self.confidence = confidence
        self.jointCount = jointCount
    }

    var area: CGFloat {
        normalizedBoundingBox.area
    }
}
