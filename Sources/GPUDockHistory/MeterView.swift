import Cocoa

/// A thin rounded horizontal meter (used for the GPU-memory-vs-budget gauge).
/// Track uses a semantic gray so it adapts to the theme; the fill uses the
/// graph tint.
final class MeterView: NSView {
    var fraction: CGFloat = 0 { didSet { needsDisplay = true } }
    var color: NSColor = .systemGreen { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.height / 2

        let track = NSBezierPath(roundedRect: bounds, xRadius: r, yRadius: r)
        NSColor.tertiaryLabelColor.setFill()
        track.fill()

        let clamped = min(max(fraction, 0), 1)
        guard clamped > 0 else { return }
        let width = max(bounds.height, bounds.width * clamped)
        let fillRect = NSRect(x: 0, y: 0, width: width, height: bounds.height)
        let fill = NSBezierPath(roundedRect: fillRect, xRadius: r, yRadius: r)
        color.setFill()
        fill.fill()
    }
}
