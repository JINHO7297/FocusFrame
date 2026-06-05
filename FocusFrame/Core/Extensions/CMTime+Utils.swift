import AVFoundation

extension CMTime {
    var displayString: String {
        guard seconds.isFinite else { return "00:00" }
        let totalSeconds = max(0, Int(seconds.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func < (lhs: CMTime, rhs: CMTime) -> Bool {
        CMTimeCompare(lhs, rhs) < 0
    }
}

