import CoreGraphics

enum CropAspectRatio: String, CaseIterable, Identifiable {
    case vertical9x16
    case square1x1
    case portrait4x5
    case horizontal16x9

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vertical9x16:
            return "9:16"
        case .square1x1:
            return "1:1"
        case .portrait4x5:
            return "4:5"
        case .horizontal16x9:
            return "16:9"
        }
    }

    var widthToHeight: CGFloat {
        switch self {
        case .vertical9x16:
            return 9 / 16
        case .square1x1:
            return 1
        case .portrait4x5:
            return 4 / 5
        case .horizontal16x9:
            return 16 / 9
        }
    }

    var defaultOutputSize: CGSize {
        switch self {
        case .vertical9x16:
            return CGSize(width: 1080, height: 1920)
        case .square1x1:
            return CGSize(width: 1080, height: 1080)
        case .portrait4x5:
            return CGSize(width: 1080, height: 1350)
        case .horizontal16x9:
            return CGSize(width: 1920, height: 1080)
        }
    }
}

