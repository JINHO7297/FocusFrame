import CoreGraphics

extension CGRect {
    var area: CGFloat {
        max(0, width) * max(0, height)
    }

    func clamped(to bounds: CGRect) -> CGRect {
        var rect = self

        if rect.width > bounds.width {
            rect.size.width = bounds.width
        }
        if rect.height > bounds.height {
            rect.size.height = bounds.height
        }

        rect.origin.x = min(max(rect.origin.x, bounds.minX), bounds.maxX - rect.width)
        rect.origin.y = min(max(rect.origin.y, bounds.minY), bounds.maxY - rect.height)
        return rect
    }

    func interpolated(to target: CGRect, amount: CGFloat) -> CGRect {
        let t = min(max(amount, 0), 1)
        return CGRect(
            x: origin.x + (target.origin.x - origin.x) * t,
            y: origin.y + (target.origin.y - origin.y) * t,
            width: width + (target.width - width) * t,
            height: height + (target.height - height) * t
        )
    }

    /// Converts Vision's normalized rectangle into display-space pixels.
    ///
    /// Vision bounding boxes are normalized to `[0, 1]` and use a lower-left origin.
    /// AVFoundation export math in this app uses display-oriented pixel coordinates
    /// with an upper-left origin, so the y-axis must be flipped with `1 - maxY`.
    static func displayRect(fromVisionNormalized rect: CGRect, in displaySize: CGSize) -> CGRect {
        CGRect(
            x: rect.minX * displaySize.width,
            y: (1 - rect.maxY) * displaySize.height,
            width: rect.width * displaySize.width,
            height: rect.height * displaySize.height
        )
    }
}

