import AVKit
import SwiftUI

struct VideoPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: url)
        controller.showsPlaybackControls = true
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if (controller.player?.currentItem?.asset as? AVURLAsset)?.url != url {
            controller.player = AVPlayer(url: url)
        }
    }
}

