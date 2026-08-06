import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Renders the macOS master icon: the refined C-Play mark (variant B) on the
// site's sunset ramp, inset in the rounded-square silhouette macOS icons use
// (unlike iOS, macOS art is not full-bleed — the system draws no mask, so the
// shape and its padding are part of the artwork).
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
ctx.setFillColor(color(0x7C3AED))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()

// The site's 115° sunset ramp, upper-left to lower-right of the body.
let ramp = CGGradient(
    colorsSpace: space,
    colors: [color(0xF7941E), color(0xE0447C), color(0x7C3AED)] as CFArray,
    locations: [0, 0.55, 1])!
ctx.drawLinearGradient(
    ramp,
    start: CGPoint(x: 130, y: 890), end: CGPoint(x: 890, y: 130),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

// Top-left bloom — the same light logic as the landing page's ambient orbs.
let bloom = CGGradient(
    colorsSpace: space,
    colors: [color(0xFFE3B8, 0.45), color(0xFFD9C2, 0.12), color(0xFFFFFF, 0)] as CFArray,
    locations: [0, 0.45, 1])!
ctx.drawRadialGradient(
    bloom,
    startCenter: CGPoint(x: 347, y: 743), startRadius: 0,
    endCenter: CGPoint(x: 347, y: 743), endRadius: 618,
    options: [])

// Mark (variant B, scaled to the 824 body): slimmer ring, flat terminals,
// bigger triangle, nudged right so the open C reads centered.
let center = CGPoint(x: 520, y: 512)
let ringRadius: CGFloat = 222
let stroke: CGFloat = 111
let gapHalf: CGFloat = 39 * .pi / 180

let ring = CGMutablePath()
ring.addArc(center: center, radius: ringRadius, startAngle: gapHalf, endAngle: -gapHalf, clockwise: false)
ctx.setStrokeColor(color(0xFFFFFF))
ctx.setLineWidth(stroke)
ctx.setLineCap(.butt)
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

let triangle = [
    CGPoint(x: center.x - 49, y: center.y + 95),
    CGPoint(x: center.x - 49, y: center.y - 95),
    CGPoint(x: center.x + 115, y: center.y),
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
