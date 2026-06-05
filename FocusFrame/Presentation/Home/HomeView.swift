import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    VideoPickerView(selection: $viewModel.selectedPickerItem)

                    if let selectedVideo = viewModel.selectedVideo {
                        selectedVideoCard(selectedVideo)
                    }

                    PrimaryButton(
                        title: viewModel.selectedVideo == nil ? "영상을 먼저 선택해주세요" : "사람 따라가기 크롭 시작",
                        systemImage: "wand.and.stars",
                        isDisabled: !viewModel.canProcess
                    ) {
                        Task { await viewModel.processSelectedVideo() }
                    }

                    ProcessingView(state: viewModel.processingState)

                    if let resultURL = viewModel.resultURL {
                        ResultView(url: resultURL) {
                            Task { await viewModel.saveResult() }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.selectedPickerItem) { item in
                Task { await viewModel.loadSelectedVideo(item) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("FocusFrame")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("On-device")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.softPrimary)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("사람을 따라가는\n세로 영상을 만들어요")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("프레임별로 사람 위치를 추적하고, 자연스럽게 움직이는 9:16 크롭 영상으로 내보냅니다.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                featurePill("9:16")
                featurePill("오디오 유지")
                featurePill("서버 없음")
            }
        }
    }

    private func selectedVideoCard(_ video: VideoAsset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("선택한 영상")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(video.fileName)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .lineLimit(2)
            }

            VideoPreviewView(url: video.url)
                .frame(height: 238)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.vertical, 8)

            HStack(spacing: 8) {
                metadataTile(title: "길이", value: video.durationText)
                metadataTile(title: "해상도", value: video.resolutionText)
                metadataTile(title: "용량", value: video.fileSizeText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private func metadataTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryInk)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func featurePill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.secondaryInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.card)
            .clipShape(Capsule())
    }
}

#Preview {
    HomeView()
}
