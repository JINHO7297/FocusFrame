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
            return "선택한 영상을 불러오지 못했어요."
        case .metadataUnavailable:
            return "영상 정보를 읽지 못했어요."
        case .noVideoTrack:
            return "선택한 파일에 영상 트랙이 없어요."
        case .noPersonDetected:
            return "분석한 프레임에서 사람을 찾지 못했어요."
        case .cropPlanUnavailable:
            return "이 영상의 크롭 경로를 만들지 못했어요."
        case .exportSessionUnavailable:
            return "영상 내보내기를 시작하지 못했어요."
        case .exportFailed(let message):
            return "영상 만들기에 실패했어요: \(message)"
        case .photoLibraryDenied:
            return "사진 앱 저장 권한이 허용되지 않았어요."
        case .saveFailed(let message):
            return "영상을 저장하지 못했어요: \(message)"
        case .cancelled:
            return "작업이 취소됐어요."
        }
    }
}
