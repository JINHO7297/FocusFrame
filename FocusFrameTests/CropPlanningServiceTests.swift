import AVFoundation
import XCTest
@testable import FocusFrame

final class CropPlanningServiceTests: XCTestCase {
    func testVisionRectangleConvertsToDisplaySpaceWithFlippedYAxis() {
        let rect = CGRect(x: 0.25, y: 0.20, width: 0.50, height: 0.30)
        let display = CGRect.displayRect(fromVisionNormalized: rect, in: CGSize(width: 200, height: 100))

        XCTAssertEqual(display.origin.x, 50, accuracy: 0.001)
        XCTAssertEqual(display.origin.y, 50, accuracy: 0.001)
        XCTAssertEqual(display.width, 100, accuracy: 0.001)
        XCTAssertEqual(display.height, 30, accuracy: 0.001)
    }

    func testVerticalCropPlanKeepsNineBySixteenAspectAndClampsToBounds() throws {
        let service = CropPlanningService()
        let detections = [
            PersonDetection(
                time: CMTime(seconds: 0, preferredTimescale: 600),
                normalizedBoundingBox: CGRect(x: 0.82, y: 0.20, width: 0.15, height: 0.35),
                confidence: 0.9
            )
        ]

        let frames = try service.generateCropFrames(
            detections: detections,
            videoSize: CGSize(width: 1920, height: 1080),
            aspectRatio: .vertical9x16,
            padding: 0.55,
            smoothing: 1
        )

        let crop = try XCTUnwrap(frames.first?.cropRect)
        XCTAssertGreaterThanOrEqual(crop.minX, 0)
        XCTAssertGreaterThanOrEqual(crop.minY, 0)
        XCTAssertLessThanOrEqual(crop.maxX, 1920)
        XCTAssertLessThanOrEqual(crop.maxY, 1080)
        XCTAssertEqual(crop.width / crop.height, CropAspectRatio.vertical9x16.widthToHeight, accuracy: 0.001)
    }

    func testSmoothingMovesCropPartWayTowardNextDetection() throws {
        let service = CropPlanningService()
        let detections = [
            PersonDetection(
                time: CMTime(seconds: 0, preferredTimescale: 600),
                normalizedBoundingBox: CGRect(x: 0.10, y: 0.30, width: 0.20, height: 0.30),
                confidence: 0.9
            ),
            PersonDetection(
                time: CMTime(seconds: 1, preferredTimescale: 600),
                normalizedBoundingBox: CGRect(x: 0.65, y: 0.30, width: 0.20, height: 0.30),
                confidence: 0.9
            )
        ]

        let unsmoothed = try service.generateCropFrames(
            detections: detections,
            videoSize: CGSize(width: 1920, height: 1080),
            smoothing: 1
        )
        let smoothed = try service.generateCropFrames(
            detections: detections,
            videoSize: CGSize(width: 1920, height: 1080),
            smoothing: 0.25
        )

        let firstX = try XCTUnwrap(smoothed.first?.cropRect.midX)
        let smoothedSecondX = try XCTUnwrap(smoothed.last?.cropRect.midX)
        let unsmoothedSecondX = try XCTUnwrap(unsmoothed.last?.cropRect.midX)

        XCTAssertGreaterThan(smoothedSecondX, firstX)
        XCTAssertLessThan(smoothedSecondX, unsmoothedSecondX)
    }

    func testFrameAlignedCropPlanCreatesCropForEveryOutputFrame() throws {
        let service = CropPlanningService()
        let detections = [
            PersonDetection(
                time: CMTime(seconds: 0, preferredTimescale: 600),
                normalizedBoundingBox: CGRect(x: 0.10, y: 0.30, width: 0.20, height: 0.30),
                confidence: 0.9
            ),
            PersonDetection(
                time: CMTime(seconds: 1, preferredTimescale: 600),
                normalizedBoundingBox: CGRect(x: 0.65, y: 0.30, width: 0.20, height: 0.30),
                confidence: 0.9
            )
        ]

        let frames = try service.generateFrameAlignedCropFrames(
            detections: detections,
            videoSize: CGSize(width: 1920, height: 1080),
            duration: CMTime(seconds: 1, preferredTimescale: 600),
            smoothing: 1,
            outputFrameRate: 30
        )

        XCTAssertEqual(frames.count, 31)
        XCTAssertEqual(frames.first?.time.seconds ?? -1, 0, accuracy: 0.001)
        XCTAssertEqual(frames.last?.time.seconds ?? -1, 1, accuracy: 0.001)

        let firstMidX = try XCTUnwrap(frames.first?.cropRect.midX)
        let middleMidX = frames[15].cropRect.midX
        let lastMidX = try XCTUnwrap(frames.last?.cropRect.midX)
        XCTAssertGreaterThan(middleMidX, firstMidX)
        XCTAssertLessThan(middleMidX, lastMidX)
    }

    func testFrameAlignedCropPlanUsesPoseCenterAsFramingAnchor() throws {
        let service = CropPlanningService()
        let detections = [
            PersonDetection(
                time: CMTime(seconds: 0, preferredTimescale: 600),
                normalizedBoundingBox: CGRect(x: 0.10, y: 0.10, width: 0.10, height: 0.10),
                normalizedCenter: CGPoint(x: 0.70, y: 0.25),
                confidence: 0.9
            )
        ]

        let frames = try service.generateFrameAlignedCropFrames(
            detections: detections,
            videoSize: CGSize(width: 1000, height: 1000),
            duration: CMTime(seconds: 0, preferredTimescale: 600),
            cropWidthToHeight: 1,
            smoothing: 1,
            outputFrameRate: 30
        )

        let crop = try XCTUnwrap(frames.first?.cropRect)
        XCTAssertEqual(crop.midX, 700, accuracy: 0.001)
        XCTAssertEqual(crop.midY, 750, accuracy: 0.001)
    }

    func testFrameAlignedCropPlanCanUseInputAspectRatio() throws {
        let service = CropPlanningService()
        let detections = [
            PersonDetection(
                time: CMTime(seconds: 0, preferredTimescale: 600),
                normalizedBoundingBox: CGRect(x: 0.40, y: 0.25, width: 0.10, height: 0.20),
                normalizedCenter: CGPoint(x: 0.45, y: 0.35),
                confidence: 0.9
            )
        ]

        let frames = try service.generateFrameAlignedCropFrames(
            detections: detections,
            videoSize: CGSize(width: 1920, height: 1080),
            duration: CMTime(seconds: 0, preferredTimescale: 600),
            cropWidthToHeight: 16 / 9,
            smoothing: 1,
            outputFrameRate: 30
        )

        let crop = try XCTUnwrap(frames.first?.cropRect)
        XCTAssertEqual(crop.width / crop.height, 16 / 9, accuracy: 0.001)
    }

    func testExportRenderSizePreservesInputDisplaySize() {
        let service = VideoExportService()
        let video = VideoAsset(
            url: URL(fileURLWithPath: "/tmp/input.mov"),
            fileName: "input.mov",
            duration: CMTime(seconds: 1, preferredTimescale: 600),
            naturalSize: CGSize(width: 1080, height: 1920),
            displaySize: CGSize(width: 1920, height: 1080),
            fileSizeInBytes: nil
        )

        XCTAssertEqual(service.outputRenderSize(for: video), CGSize(width: 1920, height: 1080))
    }
}
