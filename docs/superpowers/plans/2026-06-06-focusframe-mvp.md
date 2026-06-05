# FocusFrame MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS 16+ SwiftUI app that selects a user video, detects the largest visible person on-device, generates a smoothed 9:16 crop plan, exports a cropped video with audio, and lets the user preview, save, or share the result.

**Architecture:** MVVM plus service layer. Views render state and dispatch user intent, view models orchestrate use cases, use cases isolate app workflows, and services own AVFoundation, Vision, and Photos work.

**Tech Stack:** Swift, SwiftUI, AVFoundation, Vision, PhotosUI, Photos, XCTest, XcodeGen.

---

### File Structure

- `project.yml`: XcodeGen project definition for an iOS app and unit test target.
- `FocusFrame/App/FocusFrameApp.swift`: App entry point.
- `FocusFrame/Presentation/**`: SwiftUI screens, view models, and reusable components.
- `FocusFrame/Domain/Models/**`: Core value types for video metadata, detections, crop plans, and processing state.
- `FocusFrame/Domain/UseCases/**`: Workflow-facing APIs used by view models.
- `FocusFrame/Data/Services/**`: AVFoundation, Vision, crop planning, export, and Photos services.
- `FocusFrame/Core/**`: Errors, logging, file helpers, and geometry/time extensions.
- `FocusFrame/Resources/**`: Assets and property list.
- `FocusFrameTests/**`: Unit tests for geometry and crop planning logic.
- `README.md`: Overview, setup, structure, current MVP limits, and remaining work.

### Task 1: Project Scaffold and Home

- [x] Create the XcodeGen project definition.
- [x] Create the app target folder structure.
- [x] Add a minimal SwiftUI app, home screen, reusable button/progress/preview components, placeholder models, and app error type.
- [x] Generate `FocusFrame.xcodeproj`.
- [x] Commit as `feat: scaffold FocusFrame iOS app`.

### Task 2: Video Selection and Metadata

- [x] Add PhotosUI video picking through `PhotosPicker`.
- [x] Copy selected videos into a local temporary working file.
- [x] Extract file name, duration, display-oriented resolution, and file size with AVFoundation.
- [x] Show video preview and metadata in the home screen.
- [x] Commit as `feat: add video picking and metadata`.

### Task 3: Person Detection

- [x] Add Vision person detection service using sampled frames.
- [x] Use AVAssetImageGenerator with preferred transforms for orientation-aware sampling.
- [x] Select the largest bounding box per sampled frame.
- [x] Store detections with CMTime and normalized Vision coordinates.
- [x] Commit as `feat: add Vision person detection`.

### Task 4: Crop Planning

- [x] Add tests for clamp, aspect ratio, and smoothing behavior.
- [x] Convert Vision normalized boxes into display-space pixel rectangles.
- [x] Generate 9:16 padded crop frames clamped inside the display dimensions.
- [x] Smooth crop movement with exponential interpolation.
- [x] Commit as `feat: add crop planning`.

### Task 5: Video Export

- [x] Add AVFoundation export service with composition, video composition instructions, transform ramps, and audio preservation.
- [x] Export to MP4 at 1080x1920 by default.
- [x] Report export progress asynchronously.
- [x] Commit as `feat: add cropped video export`.

### Task 6: Result, Save, Share, and README

- [x] Add result preview, save to Photos, and share UI.
- [x] Handle cancellation and errors in `AppError`.
- [x] Document app overview, stack, run steps, structure, MVP limitations, and remaining work.
- [x] Commit as `docs: finish MVP documentation`.

### Task 7: Verification and Publish

- [x] Generate the project file.
- [x] Attempt unit/build verification and record environment blockers.
- [x] Commit final cleanup if needed.
- [ ] Create a GitHub repository and push the local commits.

### Verification Notes

- Xcode command-line Swift tooling is blocked until the local Xcode license is accepted with administrator credentials.
- GitHub CLI is not installed, and the current GitHub connector exposes repository inspection/PR/file APIs but not new repository creation.
