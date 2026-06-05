import AVFoundation
import CoreGraphics
import Foundation

struct VideoAsset: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let fileName: String
    let duration: CMTime
    let naturalSize: CGSize
    let displaySize: CGSize
    let fileSizeInBytes: Int64?

    var durationText: String {
        duration.displayString
    }

    var resolutionText: String {
        "\(Int(displaySize.width.rounded())) x \(Int(displaySize.height.rounded()))"
    }

    var fileSizeText: String {
        guard let fileSizeInBytes else { return "Unknown size" }
        return ByteCountFormatter.string(fromByteCount: fileSizeInBytes, countStyle: .file)
    }
}

