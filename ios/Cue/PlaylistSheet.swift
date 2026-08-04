import CueKit
import SwiftUI

/// Queue row artwork. URLs are loaded straight from the source's CDN — the
/// alternative, shipping a few hundred images through Booth, would dwarf the
/// rest of the protocol. Falls back to a marker for sources without artwork
/// (VLC's local files) and marks the playing row.
private struct QueueThumbnail: View {
    let item: PlaylistItem

    var body: some View {
        ZStack {
            if let urlString = item.artworkURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
            if item.isCurrent {
                Color.black.opacity(0.45)
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.17, green: 0.15, blue: 0.25), Color(red: 0.09, green: 0.08, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "music.note")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.35))
        }
    }
}

/// The playing source's queue, pulled on demand — the browser tab's when the
/// extension is providing, otherwise VLC's.
struct PlaylistSheet: View {
    @EnvironmentObject private var client: CueClient
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if client.playlistLoading && client.playlist == nil {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let items = client.playlist, !items.isEmpty {
                    List(items) { item in
                        Button {
                            client.send(.playPlaylistItem, value: Double(item.id))
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                QueueThumbnail(item: item)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .lineLimit(1)
                                        .foregroundStyle(item.isCurrent ? .white : .white.opacity(0.9))
                                    if let subtitle = item.subtitle, !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                Spacer(minLength: 8)
                                if let duration = item.duration {
                                    Text(RemoteView.timeString(duration))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .listRowBackground(Color.white.opacity(item.isCurrent ? 0.10 : 0.04))
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.4))
                        Text("No playlist available")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Play something in YouTube Music with the Cue Bridge extension installed, or open a playlist in VLC.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(BackdropView(artwork: nil, brand: nil))
            .navigationTitle("Up Next")
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
}
