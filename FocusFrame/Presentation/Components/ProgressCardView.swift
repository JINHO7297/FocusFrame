import SwiftUI

struct ProgressCardView: View {
    let state: ProcessingState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(state.message)
                .font(.headline)

            if state.isWorking {
                ProgressView(value: state.progress)
                    .progressViewStyle(.linear)
                Text("\(Int((state.progress * 100).rounded()))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

