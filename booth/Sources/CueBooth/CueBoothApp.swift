import AppKit
import SwiftUI

@main
struct CueBoothApp: App {
    @StateObject private var media = MediaState.shared

    init() {
        let bundled = Bundle.main.bundleIdentifier != nil
        DispatchQueue.main.async {
            // Packaged, Booth is an LSUIElement menu bar app and must stay an
            // accessory; running from `swift run` there's no bundle, so
            // promote it to a regular app or its window never comes forward.
            if !bundled {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }
            MediaState.shared.start()
        }
    }

    var body: some Scene {
        WindowGroup(id: "dashboard") {
            DashboardView()
                .environmentObject(media)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(media)
        } label: {
            Image(nsImage: .cueMenuBarGlyph)
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject private var media: MediaState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if media.nowPlaying.isEmpty {
            Text("Nothing playing")
        } else {
            Text("\(media.nowPlaying.title ?? "Untitled") — \(media.nowPlaying.artist ?? "")")
            Button(media.nowPlaying.playing ? "Pause" : "Play") {
                media.handle(.init(action: .togglePlayPause))
            }
            Button("Next track") { media.handle(.init(action: .nextTrack)) }
        }
        Divider()
        Button("Open Dashboard") {
            openWindow(id: "dashboard")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Quit Cue Booth") { NSApp.terminate(nil) }
    }
}

extension NSImage {
    /// The C-Play mark as a menu bar template image, so it picks up the
    /// system's light/dark and highlight treatment automatically.
    static let cueMenuBarGlyph: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let inset: CGFloat = 1.5
            let body = rect.insetBy(dx: inset, dy: inset)
            let lineWidth: CGFloat = 2.6
            let radius = (body.width - lineWidth) / 2
            let center = NSPoint(x: body.midX, y: body.midY)

            NSColor.black.setStroke()
            let ring = NSBezierPath()
            ring.appendArc(withCenter: center, radius: radius, startAngle: 38, endAngle: -38, clockwise: true)
            ring.lineWidth = lineWidth
            ring.lineCapStyle = .round
            ring.stroke()

            NSColor.black.setFill()
            let triangle = NSBezierPath()
            let scale = radius * 0.62
            triangle.move(to: NSPoint(x: center.x - scale * 0.55, y: center.y + scale * 0.8))
            triangle.line(to: NSPoint(x: center.x - scale * 0.55, y: center.y - scale * 0.8))
            triangle.line(to: NSPoint(x: center.x + scale * 0.85, y: center.y))
            triangle.close()
            triangle.fill()
            return true
        }
        image.isTemplate = true
        return image
    }()
}
