import SwiftUI

struct ProgressCardView: View {
    let state: ProcessingState

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tint.opacity(0.12))
                Image(systemName: iconName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 10) {
                Text(state.message)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)

                if state.isWorking {
                    ProgressView(value: state.progress)
                        .tint(AppTheme.primary)
                        .progressViewStyle(.linear)
                    Text("\(Int((state.progress * 100).rounded()))% 진행 중")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryInk)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private var tint: Color {
        switch state.phase {
        case .failed:
            return .red
        case .completed:
            return .green
        default:
            return AppTheme.primary
        }
    }

    private var iconName: String {
        switch state.phase {
        case .loadingVideo:
            return "tray.and.arrow.down"
        case .analyzing:
            return "person.crop.rectangle"
        case .planning:
            return "point.3.connected.trianglepath.dotted"
        case .exporting:
            return "square.and.arrow.up"
        case .completed:
            return "checkmark"
        case .failed:
            return "exclamationmark"
        case .idle:
            return "circle"
        }
    }
}
