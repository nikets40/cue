import CueKit
import SwiftUI

/// Everything open that could play — browser tabs, QuickTime documents, VLC —
/// whether or not it's currently playing. Tapping one starts it, which is what
/// makes macOS treat it as the now-playing source.
struct SourcesSheet: View {
    @EnvironmentObject private var client: CueClient
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if client.sourcesLoading && client.sources == nil {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let sources = client.sources, !sources.isEmpty {
                    List(sources) { source in
                        Button {
                            client.send(.activateSource, target: source.id)
                            dismiss()
                        } label: {
                            row(source)
                        }
                        .listRowBackground(Color.white.opacity(source.isActive ? 0.10 : 0.04))
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    empty
                }
            }
            .background(BackdropView(artwork: nil, brand: nil))
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func row(_ source: MediaSource) -> some View {
        HStack(spacing: 12) {
            SourceIcon(source: source)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.title)
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(source.isActive ? 1 : 0.9))
                if let subtitle = source.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer(minLength: 8)
            if source.isActive {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
            } else if source.playing {
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                Image(systemName: "pause.fill")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .contentShape(Rectangle())
    }

    private var empty: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.4))
            Text("Nothing open")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Open something in Chrome, QuickTime, or VLC and it'll show up here.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SourceIcon: View {
    let source: MediaSource

    var body: some View {
        ZStack {
            if let urlString = source.artworkURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: 42, height: 42)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.17, green: 0.15, blue: 0.25), Color(red: 0.09, green: 0.08, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            if let brand = source.service.flatMap(ServiceBrand.init(rawValue:)) {
                Image(brand.asset).resizable().scaledToFit().padding(8)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var symbol: String {
        switch source.kind {
        case .browserTab: "globe"
        case .quickTime: "play.rectangle"
        case .vlc: "film"
        }
    }
}
