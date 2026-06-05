import Foundation

@MainActor
final class ResultViewModel: ObservableObject {
    @Published var url: URL?
}

