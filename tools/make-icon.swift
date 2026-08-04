import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Renders the Cue app icon (C-Play mark on the Backdrop sunset wash) at
// 1024x1024 in three appearance variants per the HIG: default, dark, tinted.
//
//   swift tools/make-icon.swift <output-directory>
//
// HIG compliance notes:
// - Full-bleed square, no pre-rounded corners (system masks), no baked-in
//   shadows/highlights (Liquid Glass supplies those).
// - Two filled shapes, thick stroke (11.5% of canvas), rounded triangle
//   corners — nothing thin or sharp to fall apart at 60 pt.
// - Mark occupies ~56% of canvas, optically centered.

let size = 1024
let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")

struct RGBA { let r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat }
func color(_ hex: UInt32, _ alpha: CGFloat = 1, dim: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255 * dim,
        green: CGFloat((hex >> 8) & 0xFF) / 255 * dim,
        blue: CGFloat(hex & 0xFF) / 255 * dim,
        alpha: alpha)
}

func makeContext() -> CGContext {
    CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func drawBackground(_ ctx: CGContext, dim: CGFloat) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    ctx.setFillColor(color(0x241A4A, 1, dim: dim))
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

    // Sunset wash: warm radial from the upper left, like blurred album art.
    let colors = [
        color(0xFF9D6C, 1, dim: dim),
        color(0xD4507A, 1, dim: dim),
        color(0x5B2A86, 1, dim: dim),
        color(0x241A4A, 1, dim: dim),
    ] as CFArray
    let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.34, 0.70, 1])!
    // CG origin is bottom-left; the warm source sits off-canvas upper-left so
    // the hotspot reads as a wash, not a spotlight blob.
    ctx.drawRadialGradient(
        gradient,
        startCenter: CGPoint(x: 130, y: 950), startRadius: 0,
        endCenter: CGPoint(x: 130, y: 950), endRadius: 1420,
        options: [.drawsAfterEndLocation])

    // Faint magenta counter-glow bottom-right so corners don't go dead.
    let glow = CGGradient(
        colorsSpace: space,
        colors: [color(0xD4507A, 0.35, dim: dim), color(0xD4507A, 0)] as CFArray,
        locations: [0, 1])!
    ctx.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: 850, y: 170), startRadius: 0,
        endCenter: CGPoint(x: 850, y: 170), endRadius: 620,
        options: [])
}

func roundedTrianglePath(vertices: [CGPoint], radius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let mid = CGPoint(
        x: (vertices[0].x + vertices[1].x) / 2,
        y: (vertices[0].y + vertices[1].y) / 2)
    path.move(to: mid)
    for i in 0..<3 {
        let corner = vertices[(i + 1) % 3]
        let next = vertices[(i + 2) % 3]
        path.addArc(tangent1End: corner, tangent2End: next, radius: radius)
    }
    path.closeSubpath()
    return path
}

func drawMark(_ ctx: CGContext, ink: CGColor) {
    // The right-facing gap leaves the ring's mass left of geometric center;
    // nudge the whole mark right so it sits optically centered.
    let center = CGPoint(x: 522, y: 512)
    let ringRadius: CGFloat = 230
    let stroke: CGFloat = 118

    // C ring: gap faces right, 76 degrees wide, round caps.
    let gapHalf: CGFloat = 38 * .pi / 180
    let ring = CGMutablePath()
    ring.addArc(
        center: center, radius: ringRadius,
        startAngle: gapHalf, endAngle: -gapHalf, clockwise: false)
    ctx.setStrokeColor(ink)
    ctx.setLineWidth(stroke)
    ctx.setLineCap(.round)
    ctx.addPath(ring)
    ctx.strokePath()

    // Play triangle, pointing into the gap. Shifted right so its centroid —
    // not its bounding box — sits at the ring's optical center.
    let shift: CGFloat = 18
    let vertices = [
        CGPoint(x: center.x - 89 + shift, y: center.y + 124),
        CGPoint(x: center.x - 89 + shift, y: center.y - 124),
        CGPoint(x: center.x + 132 + shift, y: center.y),
    ]
    ctx.setFillColor(ink)
    ctx.addPath(roundedTrianglePath(vertices: vertices, radius: 26))
    ctx.fillPath()
}

func write(_ ctx: CGContext, to name: String) {
    let url = outDir.appendingPathComponent(name)
    guard let image = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fatalError("could not write \(name)") }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.path)")
}

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// Default
let def = makeContext()
drawBackground(def, dim: 1)
drawMark(def, ink: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
write(def, to: "icon-default.png")

// Dark: same composition, house lights further down (HIG: keep color bg, subdued).
let dark = makeContext()
drawBackground(dark, dim: 0.52)
drawMark(dark, ink: CGColor(red: 1, green: 1, blue: 1, alpha: 0.96))
write(dark, to: "icon-dark.png")

// Tinted: grayscale-ready — white mark on transparent, system supplies tint + base.
let tinted = makeContext()
drawMark(tinted, ink: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
write(tinted, to: "icon-tinted.png")
