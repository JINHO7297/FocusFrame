import SwiftUI

struct ProcessingView: View {
    let state: ProcessingState

    var body: some View {
        switch state.phase {
        case .idle:
            EmptyView()
        case .failed:
            ProgressCardView(state: state)
                .foregroundStyle(.red)
        case .loadingVideo, .analyzing, .planning, .exporting, .completed:
            ProgressCardView(state: state)
        }
    }
}

