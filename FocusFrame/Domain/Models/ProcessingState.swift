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

    static let idle = ProcessingState(phase: .idle, progress: 0, message: "준비됐어요")
    static let loadingVideo = ProcessingState(phase: .loadingVideo, progress: 0, message: "영상을 불러오고 있어요")
    static let planning = ProcessingState(phase: .planning, progress: 0, message: "사람을 따라갈 경로를 계산하고 있어요")
    static let completed = ProcessingState(phase: .completed, progress: 1, message: "영상 만들기가 끝났어요")

    static func analyzing(progress: Double) -> ProcessingState {
        ProcessingState(phase: .analyzing, progress: progress, message: "프레임별 사람 위치를 찾고 있어요")
    }

    static func exporting(progress: Double) -> ProcessingState {
        ProcessingState(phase: .exporting, progress: progress, message: "사람을 따라가는 크롭 영상을 만들고 있어요")
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
