// make-icon.swift — render the app icon as a set of PNGs for the macOS
// AppIcon.appiconset. No dependencies; AppKit/CoreGraphics only, mirroring how
// the app draws its dock tile (see Sources/GPUDockHistory/GPUHistoryView.swift).
//
// The icon is an honest depiction of the product: a green GPU-utilization
// history graph. It borrows the modern macOS system-utility form (inset
// rounded-square tile, baseline grid, soft contact shadow) but is deliberately
// NOT a replica of Activity Monitor's icon — different composition (padded
// squircle tile rather than a full-bleed screen, a single smoothed trace with
// a bright current-value stroke).
//
// Design notes (redesigned 2026-07-27, "silkscreen" direction):
//   - The trace bleeds off both edges and its fill runs to the tile floor.
//     The previous version drew the plot as a floating rectangle inset from
//     the tile, which read as a chart pasted onto a tile rather than an
//     instrument face.
//   - The series is shaped like real GPU load — idle, a ramp, sustained work
//     with a dip, a second climb — and is Catmull-Rom smoothed. The previous
//     monotonic zigzag read as a stock-ticker cliche.
//   - No top gloss. That highlight is an iOS-6-era convention.
//   - The "GPU" wordmark is set as an instrument annotation: SF Pro semibold
//     (NOT .rounded, which read as a sticker), ~10.5% of the tile, widely
//     tracked, 62% white. It is skipped below 64px, where three letters are an
//     illegible smudge and the trace alone reads fine.
//
// Usage:  swift scripts/make-icon.swift [output-dir]
//   output-dir defaults to Resources/Assets.xcassets/AppIcon.appiconset
//   Each PNG is rendered natively at its target pixel size for crispness.

import AppKit

let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Resources/Assets.xcassets/AppIcon.appiconset"

// A plausible GPU-utilization history: idle, a ramp into sustained load with
// a dip when work drains, then a second climb. Low on the left, which leaves
// the top-left open for the wordmark.
let load: [CGFloat] = [
    0.07, 0.09, 0.08, 0.14, 0.38, 0.61, 0.68, 0.64,
    0.72, 0.83, 0.90, 0.86, 0.93, 0.79, 0.52, 0.44,
    0.58, 0.75, 0.81, 0.77,
]

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

/// Catmull-Rom through the sample points, emitted as cubic beziers.
func smooth(_ pts: [CGPoint]) -> NSBezierPath {
    let p = NSBezierPath()
    guard pts.count > 1 else { return p }
    p.move(to: pts[0])
    for i in 0..<(pts.count - 1) {
        let p0 = pts[max(i - 1, 0)], p1 = pts[i]
        let p2 = pts[i + 1], p3 = pts[min(i + 2, pts.count - 1)]
        let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
        let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
        p.curve(to: p2, controlPoint1: c1, controlPoint2: c2)
    }
    return p
}

func samplePoints(_ vals: [CGFloat], x0: CGFloat, x1: CGFloat,
                  y0: CGFloat, h: CGFloat) -> [CGPoint] {
    vals.enumerated().map { i, v in
        CGPoint(x: x0 + (x1 - x0) * CGFloat(i) / CGFloat(vals.count - 1),
                y: y0 + h * v)
    }
}

func drawIcon(_ S: CGFloat) {
    // Modern macOS icon grid: inset squircle with transparent margins that
    // also carry the contact shadow.
    let margin = S * 0.098
    let sq = CGRect(x: margin, y: margin, width: S - 2 * margin, height: S - 2 * margin)
    let corner = sq.width * 0.2237
    let squircle = NSBezierPath(roundedRect: sq, xRadius: corner, yRadius: corner)

    // Soft contact shadow, so the tile sits in the Dock like a system icon.
    NSGraphicsContext.current?.saveGraphicsState()
    let contact = NSShadow()
    contact.shadowColor = rgb(0, 0, 0, 0.35)
    contact.shadowOffset = NSSize(width: 0, height: -S * 0.012)
    contact.shadowBlurRadius = S * 0.035
    contact.set()
    rgb(0, 0, 0, 1).setFill()
    squircle.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    // Near-black instrument face (the live tile is pure black; this is a
    // touch lighter so the tile reads as an object, not a hole).
    NSGradient(starting: rgb(0.09, 0.10, 0.11), ending: rgb(0.03, 0.04, 0.04))!
        .draw(in: squircle, angle: -90)

    NSGraphicsContext.current?.saveGraphicsState()
    squircle.addClip()

    // The trace overruns the tile horizontally so it bleeds off both edges.
    let bleed = sq.width * 0.10
    let x0 = sq.minX - bleed, x1 = sq.maxX + bleed
    let baseY = sq.minY
    let plotH = sq.height * 0.72

    // Baseline grid at 25/50/75% (echoes the dock tile), edge to edge.
    rgb(1, 1, 1, 0.07).setStroke()
    for frac: CGFloat in [0.25, 0.5, 0.75] {
        let y = baseY + plotH * frac
        let line = NSBezierPath()
        line.move(to: CGPoint(x: sq.minX, y: y))
        line.line(to: CGPoint(x: sq.maxX, y: y))
        line.lineWidth = max(1, S * 0.0035)
        line.stroke()
    }

    let trace = smooth(samplePoints(load, x0: x0, x1: x1, y0: baseY, h: plotH))

    // Area under the curve, fading out toward the tile floor.
    let area = trace.copy() as! NSBezierPath
    area.line(to: CGPoint(x: x1, y: sq.minY - S))
    area.line(to: CGPoint(x: x0, y: sq.minY - S))
    area.close()
    NSGradient(starting: rgb(0.20, 0.83, 0.45, 0.55),
               ending: rgb(0.14, 0.60, 0.34, 0.02))!.draw(in: area, angle: -90)

    // The current trace: one confident stroke with a soft phosphor glow.
    trace.lineWidth = max(1.5, S * 0.030)
    trace.lineCapStyle = .round
    trace.lineJoinStyle = .round
    NSGraphicsContext.current?.saveGraphicsState()
    let glow = NSShadow()
    glow.shadowColor = rgb(0.25, 1.0, 0.50, 0.45)
    glow.shadowBlurRadius = S * 0.05
    glow.shadowOffset = .zero
    glow.set()
    rgb(0.38, 0.95, 0.55).setStroke()
    trace.stroke()
    NSGraphicsContext.current?.restoreGraphicsState()

    // "GPU" annotation in the top-left the rising trace leaves open — without
    // it the chart reads as a generic stocks/analytics graph. Skipped below
    // 64px (Finder lists, menus), where the trace alone carries the icon.
    if S >= 64 {
        let fontSize = S * 0.105
        let label = NSAttributedString(string: "GPU", attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: rgb(1, 1, 1, 0.62),
            .kern: fontSize * 0.16,
        ])
        let ts = label.size()
        label.draw(at: CGPoint(x: sq.minX + sq.width * 0.115,
                               y: sq.maxY - sq.height * 0.115 - ts.height))
    }

    NSGraphicsContext.current?.restoreGraphicsState()

    // Hairline rim for edge definition.
    rgb(1, 1, 1, 0.09).setStroke()
    squircle.lineWidth = max(1, S * 0.004)
    squircle.stroke()
}

func writePNG(size: Int, to path: String) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("could not create bitmap rep at \(size)") }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("could not create graphics context")
    }
    NSGraphicsContext.current = ctx
    drawIcon(CGFloat(size))
    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("could not encode PNG at \(size)")
    }
    try! data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path) (\(size)x\(size))")
}

// Unique pixel sizes referenced by the appiconset Contents.json.
let sizes = [16, 32, 64, 128, 256, 512, 1024]

try? FileManager.default.createDirectory(
    atPath: outDir, withIntermediateDirectories: true)

for s in sizes {
    writePNG(size: s, to: "\(outDir)/icon_\(s).png")
}
print("done -> \(outDir)")
