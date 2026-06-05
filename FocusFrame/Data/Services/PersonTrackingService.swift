import Foundation

final class PersonTrackingService {
    /// MVP tracking keeps the largest pose-derived person span at each sampled time.
    /// The service boundary is intentionally separate so future person selection
    /// or re-identification can replace this strategy without changing view models.
    func trackLargestPerson(from detections: [PersonDetection]) throws -> TrackedPerson {
        guard !detections.isEmpty else {
            throw AppError.noPersonDetected
        }
        return TrackedPerson(detections: detections.sorted { $0.time.seconds < $1.time.seconds })
    }
}
