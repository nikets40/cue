import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Wraps a phone screenshot in a device bezel so it reads as a phone in READMEs
// and on the site, where CSS isn't available (GitHub strips styles).
//
//   swift tools/frame-screenshot.swift <in.png> <out.png>

guard CommandLine.arguments.count > 2 else {
    print("usage: frame-screenshot.swift <in.png> <out.png>")
    exit(1)
}
let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])

guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
      let shot = CGImageSourceCreateImageAtIndex(source, 0, nil)
else { fatalError("could not read \(input.path)") }

let shotWidth = CGFloat(shot.width)
let shotHeight = CGFloat(shot.height)

// Bezel proportions tuned against the screenshot's own corner radius so the
// glass sits concentrically inside the frame.
let bezel = (shotWidth * 0.038).rounded()
let margin = (shotWidth * 0.06).rounded()          // room for the drop shadow
let screenRadius = shotWidth * 0.105
let bodyRadius = screenRadius + bezel

let canvasWidth = Int(shotWidth + (bezel + margin) * 2)
let canvasHeight = Int(shotHeight + (bezel + margin) * 2)

let ctx = CGContext(
    data: nil, width: canvasWidth, height: canvasHeight,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

let body = CGRect(
    x: margin, y: margin,
    width: shotWidth + bezel * 2, height: shotHeight + bezel * 2)
let screen = CGRect(x: margin + bezel, y: margin + bezel, width: shotWidth, height: shotHeight)

// Body, with a soft shadow so it lifts off a light or dark page equally.
ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: -shotWidth * 0.012),
    blur: shotWidth * 0.05,
    color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
ctx.addPath(CGPath(roundedRect: body, cornerWidth: bodyRadius, cornerHeight: bodyRadius, transform: nil))
ctx.setFillColor(CGColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1))
ctx.fillPath()
ctx.restoreGState()

// A hairline highlight along the edge reads as the metal rail.
ctx.addPath(CGPath(
    roundedRect: body.insetBy(dx: bezel * 0.18, dy: bezel * 0.18),
    cornerWidth: bodyRadius * 0.94, cornerHeight: bodyRadius * 0.94, transform: nil))
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.13))
ctx.setLineWidth(max(1, shotWidth * 0.004))
ctx.strokePath()

// Screen, clipped to rounded corners.
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: screen, cornerWidth: screenRadius, cornerHeight: screenRadius, transform: nil))
ctx.clip()
ctx.draw(shot, in: screen)
ctx.restoreGState()

guard let framed = ctx.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
        output as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("could not write \(output.path)") }
CGImageDestinationAddImage(destination, framed, nil)
CGImageDestinationFinalize(destination)
print("framed \(input.lastPathComponent) -> \(output.lastPathComponent) (\(canvasWidth)x\(canvasHeight))")
