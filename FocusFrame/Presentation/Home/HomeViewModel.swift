import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var selectedPickerItem: PhotosPickerItem?
    @Published private(set) var selectedVideo: VideoAsset?
    @Published private(set) var processingState: ProcessingState = .idle
    @Published private(set) var resultURL: URL?

    private let pickVideoUseCase: PickVideoUseCase
    private let analyzePersonUseCase: AnalyzePersonUseCase
    private let generateCropPlanUseCase: GenerateCropPlanUseCase
    private let exportCroppedVideoUseCase: ExportCroppedVideoUseCase
    private let saveService: PhotoLibrarySaveService

    init(
        pickVideoUseCase: PickVideoUseCase = PickVideoUseCase(),
        analyzePersonUseCase: AnalyzePersonUseCase = AnalyzePersonUseCase(),
        generateCropPlanUseCase: GenerateCropPlanUseCase = GenerateCropPlanUseCase(),
        exportCroppedVideoUseCase: ExportCroppedVideoUseCase = ExportCroppedVideoUseCase(),
        saveService: PhotoLibrarySaveService = PhotoLibrarySaveService()
    ) {
        self.pickVideoUseCase = pickVideoUseCase
        self.analyzePersonUseCase = analyzePersonUseCase
        self.generateCropPlanUseCase = generateCropPlanUseCase
        self.exportCroppedVideoUseCase = exportCroppedVideoUseCase
        self.saveService = saveService
    }

    var canProcess: Bool {
        selectedVideo != nil && !processingState.isWorking
    }

    func loadSelectedVideo(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        processingState = .loadingVideo
        resultURL = nil

        do {
            selectedVideo = try await pickVideoUseCase.execute(item: item)
            processingState = .idle
        } catch is CancellationError {
            processingState = .failed(.cancelled)
        } catch let error as AppError {
            processingState = .failed(error)
        } catch {
            processingState = .failed(.videoSelectionFailed)
        }
    }

    func processSelectedVideo() async {
        guard let selectedVideo else { return }

        do {
            resultURL = nil
            processingState = .analyzing(progress: 0)
            let trackedPerson = try await analyzePersonUseCase.execute(video: selectedVideo) { [weak self] progress in
                self?.processingState = .analyzing(progress: progress)
            }

            processingState = .planning
            let cropFrames = try generateCropPlanUseCase.execute(trackedPerson: trackedPerson, video: selectedVideo)

            processingState = .exporting(progress: 0)
            let exportedURL = try await exportCroppedVideoUseCase.execute(
                video: selectedVideo,
                cropFrames: cropFrames
            ) { [weak self] progress in
                self?.processingState = .exporting(progress: progress)
            }

            resultURL = exportedURL
            processingState = .completed
        } catch is CancellationError {
            processingState = .failed(.cancelled)
        } catch let error as AppError {
            processingState = .failed(error)
        } catch {
            processingState = .failed(.exportFailed(error.localizedDescription))
        }
    }

    func saveResult() async {
        guard let resultURL else { return }
        do {
            try await saveService.saveVideo(at: resultURL)
        } catch let error as AppError {
            processingState = .failed(error)
        } catch {
            processingState = .failed(.saveFailed(error.localizedDescription))
        }
    }
}
