import Foundation

@MainActor
final class ProcessingViewModel: ObservableObject {
    @Published var state: ProcessingState = .idle
}

