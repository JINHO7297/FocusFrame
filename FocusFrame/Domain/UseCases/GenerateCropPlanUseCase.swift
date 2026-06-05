import Foundation

final class GenerateCropPlanUseCase {
    private let cropPlanningService: CropPlanningService

    init(cropPlanningService: CropPlanningService = CropPlanningService()) {
        self.cropPlanningService = cropPlanningService
    }

    func execute(
        trackedPerson: TrackedPerson,
        video: VideoAsset,
        aspectRatio: CropAspectRatio = .vertical9x16
    ) throws -> [CropFrame] {
        try cropPlanningService.generateCropFrames(
            detections: trackedPerson.detections,
            videoSize: video.displaySize,
            aspectRatio: aspectRatio
        )
    }
}

