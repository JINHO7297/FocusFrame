import AVFoundation
import CoreGraphics
import Foundation

struct CropFrame: Identifiable, Equatable {
    let id = UUID()
    let time: CMTime
    let cropRect: CGRect
}

