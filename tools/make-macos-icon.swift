import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Renders the macOS master icon: the same C-Play mark on the Backdrop wash,
// but inset in the rounded-square silhouette macOS icons use (unlike iOS,
// macOS art is not full-bleed — the system draws no mask, so the shape and
// its padding are part of the artwork).
//
//   swift tools/make-macos-icon.swift <output.png>

let canvas = 1024
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png")

// Apple's macOS grid: content occupies 824 pt of the 1024 canvas.
let inset: CGFloat = 100
let side = CGFloat(canvas) - inset * 2
let cornerRadius: CGFloat = 185

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: canvas, height: canvas, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

let body = CGRect(x: inset, y: inset, width: side, height: side)
let squircle = CGPath(roundedRect: body, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Soft contact shadow so the icon sits on light Finder backgrounds.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 34, color: color(0x000000, 0.32))
ctx.addPath(squircle)
ctx.setFillColor(color(0x241A4A))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()

let gradient = CGGradient(
    colorsSpace: space,
    colors: [color(0xFF9D6C), color(0xD4507A), color(0x5B2A86), color(0x241A4A)] as CFArray,
    locations: [0, 0.34, 0.70, 1])!
ctx.drawRadialGradient(
    gradient,
    startCenter: CGPoint(x: 210, y: 900), startRadius: 0,
    endCenter: CGPoint(x: 210, y: 900), endRadius: 1180,
    options: [.drawsAfterEndLocation])

let glow = CGGradient(
    colorsSpace: space,
    colors: [color(0xD4507A, 0.32), color(0xD4507A, 0)] as CFArray,
    locations: [0, 1])!
ctx.drawRadialGradient(
    glow,
    startCenter: CGPoint(x: 800, y: 220), startRadius: 0,
    endCenter: CGPoint(x: 800, y: 220), endRadius: 540,
    options: [])

// Mark, scaled to the inset body and nudged right so the open C reads centered.
let center = CGPoint(x: 520, y: 512)
let ringRadius: CGFloat = 186
let stroke: CGFloat = 95
let gapHalf: CGFloat = 38 * .pi / 180

let ring = CGMutablePath()
ring.addArc(center: center, radius: ringRadius, startAngle: gapHalf, endAngle: -gapHalf, clockwise: false)
ctx.setStrokeColor(color(0xFFFFFF))
ctx.setLineWidth(stroke)
ctx.setLineCap(.round)
ctx.addPath(ring)
ctx.strokePath()

func roundedTriangle(_ vertices: [CGPoint], radius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let mid = CGPoint(
        x: (vertices[0].x + vertices[1].x) / 2,
        y: (vertices[0].y + vertices[1].y) / 2)
    path.move(to: mid)
    for i in 0..<3 {
        path.addArc(tangent1End: vertices[(i + 1) % 3], tangent2End: vertices[(i + 2) % 3], radius: radius)
    }
    path.closeSubpath()
    return path
}

let shift: CGFloat = 14
let triangle = [
    CGPoint(x: center.x - 72 + shift, y: center.y + 100),
    CGPoint(x: center.x - 72 + shift, y: center.y - 100),
    CGPoint(x: center.x + 107 + shift, y: center.y),
]
ctx.setFillColor(color(0xFFFFFF))
ctx.addPath(roundedTriangle(triangle, radius: 21))
ctx.fillPath()

ctx.restoreGState()

guard let image = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("could not create image") }
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out.path)")
