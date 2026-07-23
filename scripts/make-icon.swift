// make-icon.swift — render the app icon as a set of PNGs for the macOS
// AppIcon.appiconset. No dependencies; AppKit/CoreGraphics only, mirroring how
// the app draws its dock tile (see Sources/GPUDockHistory/GPUHistoryView.swift).
//
// The icon is an honest depiction of the product: a green GPU-utilization
// history graph. It borrows the modern macOS system-utility form (inset
// rounded-square tile, subtle depth, baseline grid) but is deliberately NOT a
// replica of Activity Monitor's icon — different composition (padded squircle
// tile rather than a full-bleed screen, layered foreground/background traces,
// a bright current-trace stroke).
//
// Usage:  swift scripts/make-icon.swift [output-dir]
//   output-dir defaults to Resources/Assets.xcassets/AppIcon.appiconset
//   Each PNG is rendered natively at its target pixel size for crispness.

import AppKit

let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Resources/Assets.xcassets/AppIcon.appiconset"

// Utilization history for the foreground trace (fractions of plot height).
let front: [CGFloat] = [
    0.10, 0.16, 0.13, 0.24, 0.20, 0.34, 0.46, 0.38,
    0.30, 0.44, 0.58, 0.50, 0.42, 0.60, 0.74, 0.63,
    0.55, 0.70, 0.86, 0.78, 0.66, 0.80, 0.95, 0.88,
]
// Older history sits behind, damped, for depth.
let back: [CGFloat] = front.map { min($0 * 0.72 + 0.05, 0.90) }

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r, green: g, blue: b, alpha: a)
}

/// Build a closed area path from a series of heights across the plot rect.
func areaPath(_ heights: [CGFloat], in plot: CGRect) -> NSBezierPath {
    let p = NSBezierPath()
    let n = heights.count
    p.move(to: CGPoint(x: plot.minX, y: plot.minY))
    for (i, h) in heights.enumerated() {
        let x = plot.minX + plot.width * CGFloat(i) / CGFloat(n - 1)
        let y = plot.minY + plot.height * h
        p.line(to: CGPoint(x: x, y: y))
    }
    p.line(to: CGPoint(x: plot.maxX, y: plot.minY))
    p.close()
    return p
}

/// Build just the top edge (open) of a series, for the current-trace stroke.
func topLine(_ heights: [CGFloat], in plot: CGRect) -> NSBezierPath {
    let p = NSBezierPath()
    let n = heights.count
    for (i, h) in heights.enumerated() {
        let x = plot.minX + plot.width * CGFloat(i) / CGFloat(n - 1)
        let y = plot.minY + plot.height * h
        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
        else { p.line(to: CGPoint(x: x, y: y)) }
    }
    return p
}

func drawIcon(_ S: CGFloat) {
    // Modern macOS icon grid: inset squircle with transparent margins.
    let margin = S * 0.098
    let sq = CGRect(x: margin, y: margin, width: S - 2 * margin, height: S - 2 * margin)
    let corner = sq.width * 0.2237
    let squircle = NSBezierPath(roundedRect: sq, xRadius: corner, yRadius: corner)

    // Graphite-green background gradient (distinct from the live tile's pure black).
    let bg = NSGradient(starting: rgb(0.11, 0.14, 0.12), ending: rgb(0.04, 0.06, 0.05))!
    bg.draw(in: squircle, angle: -90)

    NSGraphicsContext.current?.saveGraphicsState()
    squircle.addClip()

    // Plot area inside the tile.
    let plot = sq.insetBy(dx: sq.width * 0.11, dy: sq.height * 0.13)

    // Baseline grid at 25/50/75% (echoes the dock tile).
    rgb(1, 1, 1, 0.10).setStroke()
    for frac: CGFloat in [0.25, 0.5, 0.75] {
        let y = plot.minY + plot.height * frac
        let line = NSBezierPath()
        line.move(to: CGPoint(x: plot.minX, y: y))
        line.line(to: CGPoint(x: plot.maxX, y: y))
        line.lineWidth = max(1, S * 0.004)
        line.stroke()
    }

    // Background trace (older history), damped and translucent.
    let backGrad = NSGradient(starting: rgb(0.16, 0.55, 0.30, 0.55),
                              ending: rgb(0.10, 0.34, 0.20, 0.30))!
    backGrad.draw(in: areaPath(back, in: plot), angle: -90)

    // Foreground trace, brighter.
    let frontGrad = NSGradient(starting: rgb(0.22, 0.80, 0.36, 0.96),
                               ending: rgb(0.12, 0.46, 0.24, 0.62))!
    frontGrad.draw(in: areaPath(front, in: plot), angle: -90)

    // Bright current-trace line along the top of the foreground area.
    let stroke = topLine(front, in: plot)
    stroke.lineWidth = max(1.5, S * 0.012)
    stroke.lineCapStyle = .round
    stroke.lineJoinStyle = .round
    rgb(0.42, 0.93, 0.53).setStroke()
    stroke.stroke()

    // Subtle top gloss for macOS depth.
    let gloss = NSGradient(starting: rgb(1, 1, 1, 0.08), ending: rgb(1, 1, 1, 0.0))!
    let glossRect = CGRect(x: sq.minX, y: sq.midY, width: sq.width, height: sq.height / 2)
    gloss.draw(in: NSBezierPath(rect: glossRect), angle: -90)

    // "GPU" wordmark in the top-left corner the rising trace leaves open —
    // without it the chart reads as a generic stocks/analytics graph.
    // Skipped at 16px, where three letters are an illegible smudge.
    if S >= 32 {
        let fontSize = S * 0.155
        var font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
        if let rounded = font.fontDescriptor.withDesign(.rounded).flatMap({ NSFont(descriptor: $0, size: fontSize) }) {
            font = rounded
        }
        let label = NSAttributedString(string: "GPU", attributes: [
            .font: font,
            .foregroundColor: rgb(1, 1, 1, 0.92),
            .kern: fontSize * 0.06,
        ])
        let ts = label.size()
        label.draw(at: CGPoint(x: plot.minX, y: plot.maxY - ts.height))
    }

    NSGraphicsContext.current?.restoreGraphicsState()

    // Hairline rim for edge definition.
    rgb(1, 1, 1, 0.06).setStroke()
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
