import Cocoa

/// The larger utilization graph shown in the details window: a filled area with
/// a bright trace, on a fixed near-black "scope" background. Deliberately stays
/// dark in BOTH light and dark themes — matching the always-black dock tile —
/// while the surrounding window chrome adapts. Renders from `SampleHistory`.
final class HistoryScopeView: NSView {

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        let b = bounds

        NSColor(white: 0.04, alpha: 1.0).setFill()
        NSBezierPath(rect: b).fill()

        // Gridlines at 25/50/75%
        NSColor(white: 1.0, alpha: 0.10).setStroke()
        for frac: CGFloat in [0.25, 0.5, 0.75] {
            let y = b.minY + b.height * frac
            let line = NSBezierPath()
            line.move(to: NSPoint(x: b.minX, y: y))
            line.line(to: NSPoint(x: b.maxX, y: y))
            line.lineWidth = 1
            line.stroke()
        }

        let samples = SampleHistory.shared.values
        guard samples.count > 1 else { return }
        let n = samples.count
        let color = Preferences.graphColor.nsColor

        // Every sample owns a fixed slot and the newest sits at the right
        // edge, so a partly-filled buffer scrolls in from the right instead of
        // stretching across the full width. Mirrors the dock tile's slot math
        // in GPUHistoryView; once the buffer is full this is the plain
        // edge-to-edge mapping.
        let capacity = SampleHistory.shared.capacity
        let slotWidth = b.width / CGFloat(max(capacity - 1, 1))
        let firstSlot = capacity - n

        func point(_ i: Int) -> NSPoint {
            let x = b.minX + CGFloat(firstSlot + i) * slotWidth
            let y = b.minY + b.height * CGFloat(samples[i] / 100.0)
            return NSPoint(x: x, y: y)
        }

        // Filled area, dropped to the baseline under the oldest and newest
        // samples rather than the view's corners.
        let area = NSBezierPath()
        area.move(to: NSPoint(x: point(0).x, y: b.minY))
        for i in 0..<n { area.line(to: point(i)) }
        area.line(to: NSPoint(x: point(n - 1).x, y: b.minY))
        area.close()
        color.withAlphaComponent(0.30).setFill()
        area.fill()

        // Trace
        let trace = NSBezierPath()
        trace.move(to: point(0))
        for i in 1..<n { trace.line(to: point(i)) }
        trace.lineWidth = 1.5
        trace.lineJoinStyle = .round
        color.setStroke()
        trace.stroke()
    }
}
