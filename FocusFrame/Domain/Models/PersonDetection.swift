import AVFoundation
import CoreGraphics
import Foundation

struct PersonDetection: Identifiable, Equatable {
    let id = UUID()
    let time: CMTime
    let normalizedBoundingBox: CGRect
    let confidence: Float

    var area: CGFloat {
        normalizedBoundingBox.area
    }
}

