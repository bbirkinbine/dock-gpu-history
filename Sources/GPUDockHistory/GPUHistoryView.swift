import Cocoa

/// Dock-tile view that mimics Activity Monitor's CPU-history dock icon,
/// but for GPU utilization. Rounded black panel, green bars, newest at right.
final class GPUHistoryView: NSView {
    private var samples: [Double] = []
    private let maxSamples = 64

    func push(_ value: Double) {
        samples.append(value)
        if samples.count > maxSamples {
            samples.removeFirst(samples.count - maxSamples)
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let inset = bounds.insetBy(dx: bounds.width * 0.04, dy: bounds.height * 0.04)
        let radius = inset.width * 0.20
        let panel = NSBezierPath(roundedRect: inset, xRadius: radius, yRadius: radius)
        NSColor.black.setFill()
        panel.fill()
        panel.addClip()

        // Gridlines at 25/50/75%
        NSColor(white: 1.0, alpha: 0.12).setStroke()
        for frac: CGFloat in [0.25, 0.5, 0.75] {
            let y = inset.minY + inset.height * frac
            let line = NSBezierPath()
            line.move(to: NSPoint(x: inset.minX, y: y))
            line.line(to: NSPoint(x: inset.maxX, y: y))
            line.lineWidth = 1
            line.stroke()
        }

        guard !samples.isEmpty else { return }

        let barWidth = inset.width / CGFloat(maxSamples)
        NSColor.systemGreen.setFill()
        for (i, s) in samples.enumerated() {
            let slot = maxSamples - samples.count + i
            let x = inset.minX + CGFloat(slot) * barWidth
            let h = max(inset.height * CGFloat(s / 100.0), s > 0 ? 1 : 0)
            NSRect(x: x, y: inset.minY, width: barWidth, height: h).fill()
        }
    }
}
