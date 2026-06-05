import Foundation

final class AnalyzePersonUseCase {
    private let detectionService: VisionPersonDetectionService
    private let trackingService: PersonTrackingService

    init(
        detectionService: VisionPersonDetectionService = VisionPersonDetectionService(),
        trackingService: PersonTrackingService = PersonTrackingService()
    ) {
        self.detectionService = detectionService
        self.trackingService = trackingService
    }

    func execute(
        video: VideoAsset,
        progress: @escaping @Sendable (Double) async -> Void
    ) async throws -> TrackedPerson {
        let detections = try await detectionService.detectPeople(in: video, progress: progress)
        return try trackingService.trackLargestPerson(from: detections)
    }
}

