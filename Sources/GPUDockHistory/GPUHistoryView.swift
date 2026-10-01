import Cocoa

/// Dock-tile view that mimics Activity Monitor's CPU-history dock icon,
/// but for GPU utilization. Rounded black panel, colored bars, newest at right,
/// with allocated GPU memory as an optional dim fill behind them.
/// Renders from the shared `SampleHistory`; tint comes from `Preferences`.
final class GPUHistoryView: NSView {
    private let maxSamples = 64

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

        let samples = Array(SampleHistory.shared.values.suffix(maxSamples))
        guard !samples.isEmpty else { return }

        let barWidth = inset.width / CGFloat(maxSamples)
        let color = Preferences.graphColor.nsColor

        // Allocated GPU memory as a fraction of budget, drawn as a dim fill
        // behind the bars — the same dim-is-allocated, bright-is-busy reading
        // as the window's memory meter. 50% alpha is a ceiling, not a taste
        // call: above it the fill swallows the bars whenever a large model is
        // resident. Slots reporting 0 bytes are skipped (key absent, not empty).
        let budget = Double(GPUInfo.memoryBudgetBytes)
        if Preferences.showMemoryInDock, budget > 0 {
            let allocated = Array(SampleHistory.shared.allocatedBytes.suffix(maxSamples))
            color.withAlphaComponent(0.5).setFill()
            for (i, bytes) in allocated.enumerated() where bytes > 0 {
                let slot = maxSamples - allocated.count + i
                let x = inset.minX + CGFloat(slot) * barWidth
                let h = inset.height * CGFloat(min(1, Double(bytes) / budget))
                NSRect(x: x, y: inset.minY, width: barWidth, height: h).fill()
            }
        }

        color.setFill()
        for (i, s) in samples.enumerated() {
            let slot = maxSamples - samples.count + i
            let x = inset.minX + CGFloat(slot) * barWidth
            let h = max(inset.height * CGFloat(s / 100.0), s > 0 ? 1 : 0)
            NSRect(x: x, y: inset.minY, width: barWidth, height: h).fill()
        }
    }
}
