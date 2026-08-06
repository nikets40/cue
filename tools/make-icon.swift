import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Renders the Cue app icon — the refined C-Play mark (design/logo-refinement.html,
// variant B) on the site's sunset ramp, plus the dark-stage companion (variant C)
// — at 1024x1024 in the three HIG appearance variants, the watch icon, and the
// 200px rounded site tiles.
//
//   swift tools/make-icon.swift <output-directory>
//
// HIG compliance notes:
// - Full-bleed square, no pre-rounded corners (system masks), no baked-in
//   shadows/highlights (Liquid Glass supplies those).
// - Flat-cut ring terminals, rounded triangle corners; stroke is half the ring
//   radius, so nothing falls apart at 60 pt.

let size = 1024
let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!

func makeContext(_ px: Int) -> CGContext {
    CGContext(
        data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

// MARK: - Mark geometry (variant B: slimmer ring, flat terminals, bigger triangle)

// The right-facing gap leaves the ring's mass left of geometric center;
// nudge the whole mark right so it sits optically centered.
let markCenter = CGPoint(x: 522, y: 512)
let ringRadius: CGFloat = 276
let ringStroke: CGFloat = 138
let gapHalf: CGFloat = 39 * .pi / 180

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

/// The whole mark as one fillable path: the stroked ring plus the triangle.
/// One path (rather than a stroke call) so variant C can clip a single
/// gradient through it and keep one light direction across both shapes.
func markPath() -> CGPath {
    let ring = CGMutablePath()
    ring.addArc(
        center: markCenter, radius: ringRadius,
        startAngle: gapHalf, endAngle: -gapHalf, clockwise: false)
    let stroked = ring.copy(
        strokingWithWidth: ringStroke, lineCap: .butt, lineJoin: .miter, miterLimit: 10)

    // Play triangle: centroid — not bounding box — at the ring's optical center.
    let triangle = roundedTrianglePath(
        vertices: [
            CGPoint(x: markCenter.x - 61, y: markCenter.y + 118),
            CGPoint(x: markCenter.x - 61, y: markCenter.y - 118),
            CGPoint(x: markCenter.x + 143, y: markCenter.y),
        ],
        radius: 26)

    let combined = CGMutablePath()
    combined.addPath(stroked)
    combined.addPath(triangle)
    return combined
}

// MARK: - Backgrounds

/// Variant B: the site's 115° sunset ramp with a top-left bloom — the same
/// light logic as the landing page's ambient orbs.
func drawSunsetBackground(_ ctx: CGContext) {
    let ramp = CGGradient(
        colorsSpace: space,
        colors: [color(0xF7941E), color(0xE0447C), color(0x7C3AED)] as CFArray,
        locations: [0, 0.55, 1])!
    // CG origin is bottom-left: start upper-left, end lower-right.
    ctx.drawLinearGradient(
        ramp,
        start: CGPoint(x: 40, y: 964), end: CGPoint(x: 964, y: 60),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

    let bloom = CGGradient(
        colorsSpace: space,
        colors: [color(0xFFE3B8, 0.45), color(0xFFD9C2, 0.12), color(0xFFFFFF, 0)] as CFArray,
        locations: [0, 0.45, 1])!
    ctx.drawRadialGradient(
        bloom,
        startCenter: CGPoint(x: 307, y: 799), startRadius: 0,
        endCenter: CGPoint(x: 307, y: 799), endRadius: 768,
        options: [])
}

/// Variant C: the app's stage-dark, lit faintly from the upper left.
func drawStageBackground(_ ctx: CGContext) {
    ctx.setFillColor(color(0x111017))
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    let stage = CGGradient(
        colorsSpace: space,
        colors: [color(0x211D2E), color(0x17151F), color(0x111017)] as CFArray,
        locations: [0, 0.6, 1])!
    ctx.drawRadialGradient(
        stage,
        startCenter: CGPoint(x: 328, y: 819), startRadius: 0,
        endCenter: CGPoint(x: 328, y: 819), endRadius: 1229,
        options: [.drawsAfterEndLocation])
}

// MARK: - Marks

func drawMark(_ ctx: CGContext, ink: CGColor) {
    ctx.setFillColor(ink)
    ctx.addPath(markPath())
    ctx.fillPath()
}

/// Variant C's mark: the sunset ramp flows once across ring and triangle
/// together, so both shapes agree about where the light comes from.
func drawGradientMark(_ ctx: CGContext) {
    ctx.saveGState()
    ctx.addPath(markPath())
    ctx.clip()
    let ramp = CGGradient(
        colorsSpace: space,
        colors: [color(0xF7941E), color(0xE0447C), color(0x7C3AED)] as CFArray,
        locations: [0, 0.55, 1])!
    // Across the mark's bounds, upper-left to lower-right.
    ctx.drawLinearGradient(
        ramp,
        start: CGPoint(x: 177, y: 857), end: CGPoint(x: 867, y: 167),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}

// MARK: - Output

func write(_ ctx: CGContext, to name: String) {
    let url = outDir.appendingPathComponent(name)
    guard let image = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fatalError("could not write \(name)") }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.path)")
}

/// 200px rounded tile for the site and README, where nothing masks for us.
func writeTile(dark: Bool, to name: String) {
    let px = 200
    let ctx = makeContext(px)
    let scale = CGFloat(px) / CGFloat(size)
    ctx.addPath(CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: px, height: px),
        cornerWidth: 46, cornerHeight: 46, transform: nil))
    ctx.clip()
    ctx.scaleBy(x: scale, y: scale)
    if dark {
        drawStageBackground(ctx)
        drawGradientMark(ctx)
    } else {
        drawSunsetBackground(ctx)
        drawMark(ctx, ink: color(0xFFFFFF))
    }
    write(ctx, to: name)
}

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// Default: variant B.
let def = makeContext(size)
drawSunsetBackground(def)
drawMark(def, ink: color(0xFFFFFF))
write(def, to: "icon-default.png")

// Dark: variant C — the mark carries the gradient on the stage.
let dark = makeContext(size)
drawStageBackground(dark)
drawGradientMark(dark)
write(dark, to: "icon-dark.png")

// Tinted: grayscale-ready — white mark on transparent, system supplies tint + base.
let tinted = makeContext(size)
drawMark(tinted, ink: color(0xFFFFFF))
write(tinted, to: "icon-tinted.png")

// Watch: same art as default; watchOS applies its circular mask.
let watch = makeContext(size)
drawSunsetBackground(watch)
drawMark(watch, ink: color(0xFFFFFF))
write(watch, to: "icon-watch.png")

// Site tiles.
writeTile(dark: false, to: "logo.png")
writeTile(dark: true, to: "logo-dark.png")
