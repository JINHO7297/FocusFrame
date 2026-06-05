import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    VideoPickerView(selection: $viewModel.selectedPickerItem)

                    if let selectedVideo = viewModel.selectedVideo {
                        videoSummary(selectedVideo)
                        VideoPreviewView(url: selectedVideo.url)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    PrimaryButton(
                        title: "Auto Crop",
                        systemImage: "crop",
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
                .padding()
            }
            .navigationTitle("FocusFrame")
            .onChange(of: viewModel.selectedPickerItem) { item in
                Task { await viewModel.loadSelectedVideo(item) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Person-aware shortform crop")
                .font(.title2.bold())
            Text("Choose a video, detect the largest visible person on-device, and export a smoothed vertical crop.")
                .foregroundStyle(.secondary)
        }
    }

    private func videoSummary(_ video: VideoAsset) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            metadataRow(title: "File", value: video.fileName)
            metadataRow(title: "Length", value: video.durationText)
            metadataRow(title: "Resolution", value: video.resolutionText)
            metadataRow(title: "Size", value: video.fileSizeText)
        }
        .font(.subheadline)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func metadataRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .fontWeight(.semibold)
                .frame(width: 88, alignment: .leading)
            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

#Preview {
    HomeView()
}

