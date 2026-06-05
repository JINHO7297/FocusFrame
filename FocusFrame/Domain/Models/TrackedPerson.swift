import Foundation

struct TrackedPerson: Identifiable, Equatable {
    let id = UUID()
    let detections: [PersonDetection]

    var isEmpty: Bool {
        detections.isEmpty
    }
}

