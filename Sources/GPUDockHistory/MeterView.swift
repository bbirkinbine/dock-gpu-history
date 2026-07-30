import Cocoa

/// A thin rounded horizontal meter with two nested segments, used for the
/// GPU-memory-vs-budget gauge: `fraction` is the dim fill (memory allocated)
/// and `activeFraction` the bright one drawn inside it (memory the GPU is
/// touching right now). Track uses a semantic gray so it adapts to the theme;
/// both fills use the graph tint, separated by alpha rather than hue so the
/// meter still reads as one quantity.
final class MeterView: NSView {
    var fraction: CGFloat = 0 { didSet { needsDisplay = true } }
    var activeFraction: CGFloat = 0 { didSet { needsDisplay = true } }
    var color: NSColor = .systemGreen { didSet { needsDisplay = true } }

    /// Alpha of the allocated fill. Low enough to read as "reserved, not busy"
    /// against the bright active segment, high enough to stay visible over the
    /// track in both light and dark.
    private let allocatedAlpha: CGFloat = 0.4

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.height / 2

        let track = NSBezierPath(roundedRect: bounds, xRadius: r, yRadius: r)
        NSColor.tertiaryLabelColor.setFill()
        track.fill()

        // A nonzero-but-tiny reading gets a visible dot rather than nothing.
        func segmentWidth(_ f: CGFloat) -> CGFloat {
            let clamped = min(max(f, 0), 1)
            guard clamped > 0 else { return 0 }
            return max(bounds.height, bounds.width * clamped)
        }

        func fill(_ width: CGFloat, _ fillColor: NSColor) {
            guard width > 0 else { return }
            fillColor.setFill()
            NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: width, height: bounds.height),
                         xRadius: r, yRadius: r).fill()
        }

        let allocatedWidth = segmentWidth(fraction)
        // Active is a subset of allocated — that containment is what the nested
        // segments assert, so a reading that violates it (or a rounding artifact
        // from the minimum-dot width above) is clamped rather than drawn
        // overhanging the dim fill, which would just look broken.
        let activeWidth = min(segmentWidth(activeFraction), allocatedWidth)

        fill(allocatedWidth, color.withAlphaComponent(allocatedAlpha))
        fill(activeWidth, color)
    }
}
