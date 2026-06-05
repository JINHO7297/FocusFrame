import AVFoundation
import CoreGraphics

enum VideoGeometry {
    static func displaySize(naturalSize: CGSize, preferredTransform: CGAffineTransform) -> CGSize {
        let bounds = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        return CGSize(width: abs(bounds.width), height: abs(bounds.height))
    }

    /// Builds a transform that first applies the source track's orientation and then
    /// shifts the transformed image into a positive display-space coordinate system.
    ///
    /// AVFoundation track transforms can rotate portrait videos into negative x/y
    /// coordinates. Crop planning uses a positive upper-left-origin display canvas,
    /// so export transforms must normalize that oriented rectangle before applying
    /// crop translation and output scaling.
    static func displayTransform(naturalSize: CGSize, preferredTransform: CGAffineTransform) -> CGAffineTransform {
        let transformedBounds = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let normalization = CGAffineTransform(
            translationX: -transformedBounds.origin.x,
            y: -transformedBounds.origin.y
        )
        return preferredTransform.concatenating(normalization)
    }
}

