import Foundation

final class GenerateCropPlanUseCase {
    private let cropPlanningService: CropPlanningService

    init(cropPlanningService: CropPlanningService = CropPlanningService()) {
        self.cropPlanningService = cropPlanningService
    }

    func execute(
        trackedPerson: TrackedPerson,
        video: VideoAsset
    ) throws -> [CropFrame] {
        try cropPlanningService.generateFrameAlignedCropFrames(
            detections: trackedPerson.detections,
            videoSize: video.displaySize,
            duration: video.duration,
            cropWidthToHeight: video.displaySize.width / video.displaySize.height
        )
    }
}
