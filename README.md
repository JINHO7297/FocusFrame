# FocusFrame

FocusFrame is an iOS native SwiftUI MVP that turns a selected iPhone video into a person-following vertical crop. It detects the largest visible person on-device with Vision, builds a smoothed crop plan, exports a 9:16 shortform video with AVFoundation, and keeps the original audio track.

## Tech Stack

- iOS 16+
- Swift and SwiftUI
- PhotosUI for video selection
- Vision Framework for person detection
- AVFoundation for metadata, frame sampling, and export
- Photos for saving exported videos
- XCTest for crop planning and coordinate conversion tests
- XcodeGen for project generation

## Running

1. Open `FocusFrame.xcodeproj` in Xcode.
2. Select the `FocusFrame` scheme.
3. Run on an iPhone simulator or a physical iPhone.
4. Choose a video, review metadata, tap `Auto Crop`, then preview, save, or share the result.

If using command line tools, generate the project with:

```bash
xcodegen generate
```

Then build with:

```bash
xcodebuild -project FocusFrame.xcodeproj -scheme FocusFrame -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Structure

```text
FocusFrame/
  App/
    FocusFrameApp.swift
  Presentation/
    Home/
    VideoPicker/
    Processing/
    Result/
    Components/
  Domain/
    Models/
    UseCases/
  Data/
    Services/
  Core/
    Extensions/
    Utils/
    Errors/
  Resources/
    Assets.xcassets
```

## MVP Flow

1. The user selects a gallery video with PhotosUI.
2. `VideoMetadataService` reads duration, display-oriented resolution, and file details.
3. `VisionPersonDetectionService` samples frames at 5 fps and runs `VNDetectHumanRectanglesRequest`.
4. `PersonTrackingService` keeps the largest detected person per sampled frame.
5. `CropPlanningService` converts Vision boxes into display-space pixels, pads the crop, clamps it to the video bounds, and smooths movement.
6. `VideoExportService` applies transform ramps to crop the source video into a 1080x1920 MP4 while preserving audio.
7. The result can be previewed, shared, or saved to Photos.

## Current MVP Limits

- Multiple people are not re-identified across frames; the largest box is always selected.
- If people cross or one person briefly becomes larger, the target may switch.
- Fast motion can still cause crop jumps because detection is sampled at 5 fps.
- Vision human rectangle detection may miss partial bodies, unusual poses, or motion-blurred frames.
- Export transform math accounts for orientation, but unusual camera metadata should be tested with real device footage.
- There is no manual target selection or crop correction UI yet.

## Remaining Work

- Add selectable detected person tracks.
- Add 1:1, 4:5, and 16:9 controls in the UI.
- Add manual crop keyframe adjustment.
- Add cancellation controls for analysis and export.
- Add richer export presets and bitrate controls.
- Add sample video fixtures and integration tests once test media is available.

