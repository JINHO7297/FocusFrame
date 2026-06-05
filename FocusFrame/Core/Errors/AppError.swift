import Foundation

enum AppError: LocalizedError, Equatable {
    case videoSelectionFailed
    case metadataUnavailable
    case noVideoTrack
    case noPersonDetected
    case cropPlanUnavailable
    case exportSessionUnavailable
    case exportFailed(String)
    case photoLibraryDenied
    case saveFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .videoSelectionFailed:
            return "Could not load the selected video."
        case .metadataUnavailable:
            return "Could not read the video metadata."
        case .noVideoTrack:
            return "The selected file does not contain a video track."
        case .noPersonDetected:
            return "No person was detected in the sampled video frames."
        case .cropPlanUnavailable:
            return "Could not create a crop plan for the selected video."
        case .exportSessionUnavailable:
            return "Could not create a video export session."
        case .exportFailed(let message):
            return "Video export failed: \(message)"
        case .photoLibraryDenied:
            return "Photo Library save permission was not granted."
        case .saveFailed(let message):
            return "Could not save the video: \(message)"
        case .cancelled:
            return "The operation was cancelled."
        }
    }
}

