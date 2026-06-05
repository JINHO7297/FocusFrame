import Foundation

enum ProcessingPhase: Equatable {
    case idle
    case loadingVideo
    case analyzing
    case planning
    case exporting
    case completed
    case failed(AppError)
}

struct ProcessingState: Equatable {
    var phase: ProcessingPhase
    var progress: Double
    var message: String

    static let idle = ProcessingState(phase: .idle, progress: 0, message: "Ready")
    static let loadingVideo = ProcessingState(phase: .loadingVideo, progress: 0, message: "Loading video")
    static let planning = ProcessingState(phase: .planning, progress: 0, message: "Planning crop")
    static let completed = ProcessingState(phase: .completed, progress: 1, message: "Export complete")

    static func analyzing(progress: Double) -> ProcessingState {
        ProcessingState(phase: .analyzing, progress: progress, message: "Detecting person")
    }

    static func exporting(progress: Double) -> ProcessingState {
        ProcessingState(phase: .exporting, progress: progress, message: "Exporting cropped video")
    }

    static func failed(_ error: AppError) -> ProcessingState {
        ProcessingState(phase: .failed(error), progress: 0, message: error.localizedDescription)
    }

    var isWorking: Bool {
        switch phase {
        case .loadingVideo, .analyzing, .planning, .exporting:
            return true
        case .idle, .completed, .failed:
            return false
        }
    }
}

